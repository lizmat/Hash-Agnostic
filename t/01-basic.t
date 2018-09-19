use v6.c;
use Test;

use Hash::Agnostic;

class MyHash does Hash::Agnostic {
    has %!hash;

    method AT-KEY($key)          is raw { %!hash.AT-KEY($key)         }
    method BIND-KEY($key,\value) is raw { %!hash.BIND-KEY($key,value) }
    method EXISTS-KEY($key)             { %!hash.EXISTS-KEY($key)     }
    method DELETE-KEY($key)             { %!hash.DELETE-KEY($key)     }
    method keys()                       { %!hash.keys                 }
}

plan 20;

=finish

my %h is MyHash = 1 .. 10;
is %h.elems, 10, 'did we get 10 elements';
is %h.end,    9, 'is index 9 the last element';
is-deeply %h.shape, (*,), 'is the shape ok';

is %h.gist,            "[1 2 3 4 5 6 7 8 9 10]", 'does .gist work ok';
is %h.Str,              "1 2 3 4 5 6 7 8 9 10",  'does .Str work ok';
is %h.perl, "MyHash.new(1,2,3,4,5,6,7,8,9,10)", 'does .perl work ok';

subtest {
    plan 10;
    my int $value = 0;
    is $_, ++$value, "did iteration {$value -1} produce $value"
      for %h;
}, 'checking iterator';

subtest {
    plan 10;
    is %h[$_], $_ + 1, "did element $_ produce {$_ + 1}"
      for ^10;
}, 'checking [x]';

subtest {
    plan 10;
    is %h[* - $_], 11 - $_, "did element * - $_ produce {11 - $_}"
      for 1 .. 10;
}, 'checking [* - x]';

subtest {
    plan 5;
    ok %h[9]:exists, 'does last element exist';
    is %h[9]:delete, 10, 'does :delete work on last element';
    nok %h[9]:exists, 'does last element no longer exist';
    is %h.elems, 9, 'do we have one element less now: elems';
    is %h.end,   8, 'do we have one element less now: end';
}, 'deletion of last element';

subtest {
    plan 5;
    is-deeply %h[3,5,7]:exists, (True,True,True),
      'can we check existence of an existing slice';
    is-deeply %h[3,5,7]:delete, (4,6,8),
      'can we remove an existing slice';
    is-deeply %h[3,5,7]:exists, (False,False,False),
      'can we check existence of an non-existing slice';
    is %h.elems, 9, 'did we keep same number of elements';
    is %h.end,   8, 'did we keep same last element';
}, 'can we delete a slice';

subtest {
    plan 3;
    is-deeply %h[^5]:v, (1,2,3,5), 'does a value slice work';
    is-deeply %h[]:v, (1,2,3,5,7,9), 'does a value zen-slice work';
    is-deeply %h[*]:v, (1,2,3,5,7,9), 'does a value whatever-slice work';
}, 'can we do value slices';

subtest {
    plan 11;
    is-deeply %h.keys, (0,1,2,3,4,5,6,7,8),
      'does .keys work';
    is-deeply %h.values, (1,2,3,Any,5,Any,7,Any,9),
      'does .values work';
    is-deeply %h.pairs, (0=>1,1=>2,2=>3,3=>Any,4=>5,5=>Any,6=>7,7=>Any,8=>9),
      'does .pairs work';
    is-deeply %h.kv, (0,1,1,2,2,3,3,Any,4,5,5,Any,6,7,7,Any,8,9),
      'does .kv work';

    is-deeply %h.head, 1, 'does .head work';
    is-deeply %h.head(3), (1,2,3), 'does .head(3) work';
    is-deeply %h.tail, 9, 'does .tail work';
    is-deeply %h.tail(3), (7,Any,9), 'does .tail(3) work';

    is-deeply %h.list, List.new(1,2,3,Any,5,Any,7,Any,9),
      'does .list work';
    is-deeply %h.List, List.new(1,2,3,Any,5,Any,7,Any,9),
      'does .List work';
    is-deeply %h.Hash, Hash.new(1,2,3,Any,5,Any,7,Any,9),
      'does .Hash work';
}, 'check iterator based methods';

subtest {
    plan 14;
    is-deeply %h.push(42), %h, 'did .push return self';
    is %h.elems, 10, 'did we increase number of elements';
    is %h.end,    9, 'did we increase the last index';
    is %h[9], 42, 'did we get the right value after .push';

    is-deeply %h.append(666), %h, 'did .append return self';
    is %h.elems, 11, 'did we increase number of elements';
    is %h.end,   10, 'did we increase the last index';
    is %h[10],  666, 'did we get the right value after .append';

    is %h.pop,  666, 'did .pop return right value I';
    is %h.pop,   42, 'did .pop return right value II';
    is %h.elems,  9, 'did we decrease number of elements';
    is %h.end,    8, 'did we decrease the last index';
    is %h[ 9],  Any, 'did the elements value disappear I';
    is %h[10],  Any, 'did the elements value disappear II';
}, 'test .push / .append / .pop one element';

subtest {
    plan 11;
    is-deeply %h.push([42,666]), %h, 'did .push return self';
    is %h.elems, 10, 'did we increase number of elements';
    is %h.end,    9, 'did we increase the last index';
    is-deeply %h[9], [42,666], 'did we get the right value after .push';

    is-deeply %h.append([999,1000]), %h, 'did .append return self';
    is %h.elems, 12, 'did we increase number of elements';
    is %h.end,   11, 'did we increase the last index';
    is %h[10],  999, 'did we get the right value after .append I';
    is %h[11], 1000, 'did we get the right value after .append II';

    %h.pop for ^3;
    is %h.elems,  9, 'did we decrease number of elements';
    is %h.end,    8, 'did we decrease the last index';
}, 'test .push / .append / .pop one flattenable element';

subtest {
    plan 12;
    is-deeply %h.push(42,666), %h, 'did .push return self';
    is %h.elems, 11, 'did we increase number of elements';
    is %h.end,   10, 'did we increase the last index';
    is %h[ 9],   42, 'did we get the right value after .push I';
    is %h[10],  666, 'did we get the right value after .push II';

    is-deeply %h.append(999,1000), %h, 'did .append return self';
    is %h.elems, 13, 'did we increase number of elements';
    is %h.end,   12, 'did we increase the last index';
    is %h[11],  999, 'did we get the right value after .append I';
    is %h[12], 1000, 'did we get the right value after .append II';

    %h.pop for ^4;
    is %h.elems,  9, 'did we decrease number of elements';
    is %h.end,    8, 'did we decrease the last index';
}, 'test .push / .append / .pop multiple elements';

subtest {
    plan 16;
    is-deeply %h.unshift(42), %h, 'did .unshift return self';
    is %h.elems, 10, 'did we increase number of elements';
    is %h.end,    9, 'did we increase the last index';
    is %h[0], 42, 'did we get the right value after .unshift';

    is-deeply %h.prepend(666), %h, 'did .prepend return self';
    is %h.elems, 11, 'did we increase number of elements';
    is %h.end,   10, 'did we increase the last index';
    is %h[0],   666, 'did we get the right value after .prepend';

    is %h.shift, 666, 'did .shift return right value I';
    is %h.elems,  10, 'did we decrease number of elements';
    is %h.end,     9, 'did we decrease the last index';
    is %h.shift,  42, 'did .shift return right value II';
    is %h.elems,   9, 'did we decrease number of elements';
    is %h.end,     8, 'did we decrease the last index';
    is %h[ 9],   Any, 'did the elements value disappear I';
    is %h[10],   Any, 'did the elements value disappear II';
}, 'test .unshift / .prepend / .shift one element';

subtest {
    plan 11;
    is-deeply %h.unshift([42,666]), %h, 'did .unshift return self';
    is %h.elems, 10, 'did we increase number of elements';
    is %h.end,    9, 'did we increase the last index';
    is-deeply %h[0], [42,666], 'did we get the right value after .unshift';

    is-deeply %h.prepend([999,1000]), %h, 'did .prepend return self';
    is %h.elems, 12, 'did we increase number of elements';
    is %h.end,   11, 'did we increase the last index';
    is %h[0],   999, 'did we get the right value after .prepend I';
    is %h[1],  1000, 'did we get the right value after .prepend II';

    %h.shift for ^3;
    is %h.elems,  9, 'did we decrease number of elements';
    is %h.end,    8, 'did we decrease the last index';
}, 'test .unshift / .prepend / .shift one flattenable element';

subtest {
    plan 12;
    is-deeply %h.unshift(42,666), %h, 'did .unshift return self';
    is %h.elems, 11, 'did we increase number of elements';
    is %h.end,   10, 'did we increase the last index';
    is %h[0],    42, 'did we get the right value after .unshift I';
    is %h[1],   666, 'did we get the right value after .unshift II';

    is-deeply %h.prepend(999,1000), %h, 'did .prepend return self';
    is %h.elems, 13, 'did we increase number of elements';
    is %h.end,   12, 'did we increase the last index';
    is %h[0],   999, 'did we get the right value after .prepend I';
    is %h[1],  1000, 'did we get the right value after .prepend II';

    %h.shift for ^4;
    is %h.elems,  9, 'did we decrease number of elements';
    is %h.end,    8, 'did we decrease the last index';
}, 'test .unshift / .append / .shift multiple elements';

subtest {
    plan 35;
    my @b is MyHash;
    is (@b[4] = 42), 42, 'does assignment pass on the value';
    is-deeply @b[$_]:exists, False, "does element $_ not exist" for ^4;
    is-deeply @b[$_]:exists, False, "does element $_ not exist" for 5..10;
    is @b[4], 42, 'did the right value get assigned';
    is @b.elems, 5, 'did we get right number of elements initially';
    is @b.end,   4, 'did we get right last element initially';

    is @b.shift, Any, 'did we get the right 0th element';
    is @b.elems, 4, 'did we get right number of elements after shift';
    is @b.end,   3, 'did we get right last element after shift';
    is-deeply @b[4]:exists, False, 'did the last element disappear';
    is-deeply @b[$_]:exists, False, "does element $_ still not exist" for ^3;
    is @b[3], 42, 'did the right value move down one';

    is-deeply @b.unshift(666), @b, 'does unshift return self';
    is @b[0], 666, 'did the right value get unshifted';
    is-deeply @b[$_]:exists, False, "does element $_ not exist" for 1 .. 3;
    is-deeply @b[$_]:exists, False, "does element $_ not exist" for 5..10;
    is @b.elems, 5, 'did we get right number of elements after unshift';
    is @b.end,   4, 'did we get right last element after unshift';
}, 'test holes in arrays';

# vim: ft=perl6 expandtab sw=4

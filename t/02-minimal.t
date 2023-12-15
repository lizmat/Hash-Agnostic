use v6.c;
use Test;

use Hash::Agnostic;

class MinimalHash does Hash::Agnostic {
    has %!hash;

    method AT-KEY($key) is raw { %!hash.AT-KEY($key) }
    method keys()              { %!hash.keys         }
}

plan 10;

my @keys   := <a b c d e f g h>;
my @values := 42, 666, 314, 628, 271, 6, 7, 8;
my @sorted := @values.sort.List;
my @pairs  := (@keys Z=> @values).List;
my @kv     := (@keys Z @values).flat.List;

my %h is MinimalHash = @pairs;
sub test-basic() {
    subtest {
        is %h.elems, +@keys, "did we get {+@keys} elements";
        is %h.gist,
          '{a => 42, b => 666, c => 314, d => 628, e => 271, f => 6, g => 7, h => 8}',
          'does .gist work ok';
        is %h.Str,
          'a	42 b	666 c	314 d	628 e	271 f	6 g	7 h	8',
          'does .Str work ok';
        is %h.raku,
          'MinimalHash.new(:a(42),:b(666),:c(314),:d(628),:e(271),:f(6),:g(7),:h(8))',
          'does .raku work ok';
    }, 'test basic stuff after initialization';
}

test-basic;

subtest {
    plan +@keys;
    my %test = @pairs;
    is %test{.key}, .value, "did iteration {.key} produce %test{.key}"
      for %h;
}, 'checking iterator';

subtest {
    plan +@keys;
    my %test = @pairs;
    is %h{$_}, %test{$_}, "did key $_ produce %test{$_}"
      for @keys;
}, 'checking {x}';

subtest {
    plan 4;
    ok %h<g>:exists, 'does "g" exist';
    dies-ok { %h<g>:delete }, 'does :delete die';
    nok %h<z>:exists, 'does "z" not exist';
    is %h.elems, +@keys, 'do we have still have same number of elements';
}, 'can we NOT delete a key';

subtest {
    plan 4;
    is-deeply %h<d e f>:exists, (True,True,True),
      'can we check existence of an existing slice';
    dies-ok { %h<d e f>:delete },
      'can we NOT remove an existing slice';
    is-deeply %h<x y z>:exists, (False,False,False),
      'can we check existence of an non-existing slice';
    is %h.elems, +@keys, 'did we keep number of elements';
}, 'can we NOT delete a slice';

subtest {
    plan 3;
    is-deeply (%h{<a b c h z>}:v).sort, (8,42,314,666), 'does a value slice work';
    is-deeply (%h{}:v).sort, @values.sort, 'does a value zen-slice work';
    is-deeply (%h{*}:v).sort, @values.sort, 'does a value whatever-slice work';
}, 'can we do value slices';

dies-ok { %h = @pairs }, 'dies trying to re-initialize';
test-basic;

subtest {
    plan 4;
    is-deeply %h.keys.sort,            @keys, 'does .keys work';
    is-deeply %h.values.sort,        @sorted, 'does .values work';
    is-deeply %h.pairs.sort( *.key ), @pairs, 'does .pairs work';
    is-deeply %h.kv.sort,           @kv.sort, 'does .kv work';
}, 'check iterator based methods';

subtest {
    plan 3;
    is-deeply +%h, 8,    'does it numerify ok';
    is-deeply ?%h, True, 'does it boolify ok';
    is-deeply %h.Int, 8, 'does it intify ok';
}

# vim: expandtab shiftwidth=4

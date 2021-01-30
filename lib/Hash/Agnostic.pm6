use v6.c;

class X::NoImplementation is Exception {
    has $.object;
    has $.method;
    method message() {
        my $text = "No implementation of $.method method found for $.object.^name().";
        $*DEFAULT-CLEAN
          ?? "$text\nThis is needed to be able to clear an agnostic hash."
          !! $text
    }
}

role Hash::Agnostic:ver<0.0.7>:auth<cpan:ELIZABETH>
  does Associative  # .AT-KEY and friends
  does Iterable     # .iterator, basically
{

#--- These methods *MUST* be implemented by the consumer -----------------------
    method AT-KEY($) is raw { ... }
    method keys()           { ... }

#--- Internal Iterator classes that need to be specified here ------------------
    my class KV does Iterator {
        has $.backend;
        has $.iterator;
        has $!key;

        method pull-one() is raw {
            with $!key {
                my $key = $!key;
                $!key  := Mu;
                $!backend.AT-KEY($key)          # on the value now
            }
            else {
                $!key := $!iterator.pull-one    # key or IterationEnd
            }
        }
    }

#--- Associative methods that *MAY* be implemented by the consumer -------------
    method BIND-KEY(::?ROLE:D: $,$) is hidden-from-backtrace {
        X::NoImplementation.new(object => self, method => 'BIND-KEY').throw
    }

    method EXISTS-KEY(::?ROLE:D: $key) { self.AT-KEY($key).defined }

    method DELETE-KEY(::?ROLE:D: $) is hidden-from-backtrace {
        X::NoImplementation.new(object => self, method => 'DELETE-KEY').throw
    }

    method CLEAR(::?ROLE:D:) {
        my $*DEFAULT-CLEAN := True;
        self.DELETE-KEY($_) for self.keys;
    }

    method ASSIGN-KEY(::?ROLE:D: $key, \value) is raw {
        self.AT-KEY($key) = value;
    }

    multi method STORE(::?ROLE:D: *@values) {
        self.CLEAR;
        self!STORE(@values);
        self
    }

    method !STORE(@values --> Int:D) {
        my $last := Mu;
        my int $found;

        for @values {
            if $_ ~~ Pair {
                self.ASSIGN-KEY(.key, .value);
                ++$found;
            }
            elsif $_ ~~ Failure {
                .throw
            }
            elsif !$last =:= Mu {
                self.ASSIGN-KEY($last, $_);
                ++$found;
                $last := Mu;
            }
            elsif $_ ~~ Map {
                $found += self!STORE([.pairs])
            }
            else {
                $last := $_;
            }
        }

        $last =:= Mu
          ?? $found
          !! X::Hash::Store::OddNumber.new(:$found, :$last).throw
    }

#--- Hash methods that *MAY* be implemented by the consumer -------------------
    method new(::?CLASS:U: **@values is raw) {
        self.CREATE.STORE(@values, :initialize)
    }
    method iterator(::?ROLE:D:) { self.pairs.iterator }

    method elems(::?ROLE:D:)  { self.keys.elems }
    method end(::?ROLE:D:)    { self.elems - 1 }
    method values(::?ROLE:D:) { self.keys.map: { self.AT-KEY($_) } }
    method pairs(::?ROLE:D:)  { self.keys.map: { Pair.new($_, self.AT-KEY($_) ) } }

    method kv(::?ROLE:D:) {
        Seq.new( KV.new( :backend(self), :iterator(self.keys.iterator ) ) )
    }

    method list(::?ROLE:D:)  {  List.from-iterator(self.iterator) }
    method Slip(::?ROLE:D:)  {  Slip.from-iterator(self.iterator) }
    method List(::?ROLE:D:)  {  List.from-iterator(self.iterator) }
    method Array(::?ROLE:D:) { Array.from-iterator(self.iterator) }
    method Hash(::?ROLE:D:)  {  Hash.new(self) }

    method !append(@values) { ... }
    method append(::?ROLE:D: +@values is raw) { self!append(@values) }
    method push(::?ROLE:D:  **@values is raw) { self!append(@values) }

    method gist(::?ROLE:D:) {
        '{' ~ self.pairs.sort( *.key ).map( *.gist).join(", ") ~ '}'
    }
    method Str(::?ROLE:D:) {
        self.pairs.sort( *.key ).join(" ")
    }
    method perl(::?ROLE:D:) is DEPRECATED("raku") { self.raku }
    method raku(::?ROLE:D:) {
        self.perlseen(self.^name, {
          ~ self.^name
          ~ '.new('
          ~ self.pairs.sort( *.key ).map({$_<>.perl}).join(',')
          ~ ')'
        })
    }
}

=begin pod

=head1 NAME

Hash::Agnostic - be a hash without knowing how

=head1 SYNOPSIS

  use Hash::Agnostic;
  class MyHash does Hash::Agnostic {
      method AT-KEY($key)          { ... }
      method keys()                { ... }
  }

  my %a is MyHash = a => 42, b => 666;

=head1 DESCRIPTION

This module makes an C<Hash::Agnostic> role available for those classes that
wish to implement the C<Associative> role as a C<Hash>.  It provides all of
the C<Hash> functionality while only needing to implement 2 methods:

=head2 Required Methods

=head3 method AT-KEY

  method AT-KEY($key) { ... }  # simple case

  method AT-KEY($key) { Proxy.new( FETCH => { ... }, STORE => { ... } }

Return the value at the given key in the hash.  Must return a C<Proxy> that
will assign to that key if you wish to allow for auto-vivification of elements
in your hash.

=head3 method keys

  method keys() { ... }

Return the keys that currently exist in the hash, in any order that is
most convenient.

=head2 Optional Methods (provided by role)

You may implement these methods out of performance reasons yourself, but you
don't have to as an implementation is provided by this role.  They follow the
same semantics as the methods on the
L<Hash object|https://docs.perl6.org/type/Hash>.

In alphabetical order:
C<append>, C<ASSIGN-KEY>, C<elems>, C<end>, C<gist>, C<grab>, C<Hash>,
C<iterator>, C<kv>, C<list>, C<List>, C<new>, C<pairs>, C<perl>, C<push>,
C<Slip>, C<STORE>, C<Str>, C<values>

=head2 Optional Internal Methods (provided by role)

These methods may be implemented by the consumer for performance reasons
or to provide a given capability.

=head3 method BIND-KEY

  method BIND-KEY($key, $value) { ... }

Bind the given value to the given key in the hash, and return the value.
Throws an error if not implemented.

=head3 method DELETE-KEY

  method DELETE-KEY($key) { ... }

Remove the the given key from the hash and return its value if it existed
(otherwise return C<Nil>).  Throws an error if not implemented.

=head3 method EXISTS-KEY

  method EXISTS-KEY($key) { ... }

Return C<Bool> indicating whether the key exists in the hash.  Will call
C<AT-KEY> and return C<True> if the returned value is defined.

=head3 method CLEAR

  method CLEAR(--> Nil) { ... }

Reset the array to have no elements at all.  By default implemented by
repeatedly calling C<DELETE-KEY>, which will by all means, be very slow.
So it is a good idea to implement this method yourself.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/Hash-Agnostic .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018,2020,2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4

use v6.c;

sub is-container(\it) is export { it.VAR.^name ne it.^name }

role Hash::Agnostic:ver<0.0.1>:auth<cpan:ELIZABETH>
  does Associative  # .AT-KEY and friends
  does Iterable     # .iterator, basically
{

#--- These methods *MUST* be implemented by the consumer -----------------------
    method AT-KEY($)     is raw { ... }
    method BIND-KEY($,$) is raw { ... }
    method EXISTS-KEY($)        { ... }
    method DELETE-KEY($)        { ... }
    method keys()               { ... }

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

#--- Positional methods that *MAY* be implemented by the consumer --------------
    method CLEAR() {
        self.DELETE-KEY($_) for self.keys;
    }

    method ASSIGN-KEY(int $pos, \value) is raw {
        self.AT-KEY($pos) = value;
    }

    method STORE(*@values, :$initialize) {
        self.CLEAR;
        for @values {
            self.ASSIGN-KEY($_,@values.AT-KEY($_));
        }
        self
    }

#--- Hash methods that *MAY* be implemented by the consumer -------------------
    method new(::?CLASS:U: **@values is raw) {
        self.CREATE.STORE(@values)
    }
    method iterator() { self.pairs.iterator }

    method elems()  { self.keys.elems }
    method end()    { self.elems - 1 }
    method values() { self.keys.map: { self.AT-KEY($_) } }
    method pairs()  { self.keys.map: { Pair.new($_, self.AT-KEY($_) ) } }

    method kv() {
        Seq.new( KV.new( :backend(self), :iterator(self.keys.iterator ) ) )
    }

    method list()  {  List.from-iterator(self.iterator) }
    method Slip()  {  Slip.from-iterator(self.iterator) }
    method List()  {  List.from-iterator(self.iterator) }
    method Array() { Array.from-iterator(self.iterator) }
    method Hash()  {  Hash.from-iterator(self.iterator) }

    method !append(@values) {
        self.ASSIGN-KEY(self.elems,$_) for @values;
        self
    }
    method append(+@values is raw) { self!append(@values) }
    method push( **@values is raw) { self!append(@values) }

    method gist() { '{' ~ self.pairs.map( *.gist).join(",") ~ ']' }
    method Str()  { self.pairs.join(" ") }
    method perl() {
        self.perlseen(self.^name, {
          ~ self.^name
          ~ '.new('
          ~ self.pairs.map({$_<>.perl}).join(',')
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
      method AT-KEY()     { ... }
      method BIND-KEY()   { ... }
      method DELETE-KEY() { ... }
      method EXISTS-KEY() { ... }
      method keys()       { ... }
  }

  my %a is MyHash = a => 42, b => 666;

=head1 DESCRIPTION

This module makes an C<Hash::Agnostic> role available for those classes that
wish to implement the C<Associatve> role as a C<Hash>.  It provides all of
the C<Hash> functionality while only needing to implement 5 methods:

=head2 Required Methods

=head3 method AT-KEY

  method AT-KEY($key) { ... }  # simple case

  method AT-KEY($key) { Proxy.new( FETCH => { ... }, STORE => { ... } }

Return the value at the given key in the hash.  Must return a C<Proxy> that
will assign to that key if you wish to allow for auto-vivification of elements
in your hash.

=head3 method BIND-KEY

  method BIND-KEY($key, $value) { ... }

Bind the given value to the given key in the hash, and return the value.

=head3 method DELETE-KEY

  method DELETE-KEY($key) { ... }

Remove the the given key from the hash and return its value if it existed
(otherwise return C<Nil>).

=head3 method EXISTS-KEY

  method EXISTS-KEY($key) { ... }

Return C<Bool> indicating whether the key exists in the hash.

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

These methods may be implemented by the consumer for performance reasons.

=head3 method CLEAR

  method CLEAR(--> Nil) { ... }

Reset the array to have no elements at all.  By default implemented by
repeatedly calling C<DELETE-KEY>, which will by all means, be very slow.
So it is a good idea to implement this method yourself.

=head2 Exported subroutines

=head3 sub is-container

  my $a = 42;
  say is-container($a);  # True
  say is-container(42);  # False

Returns whether the given argument is a container or not.  This can be handy
for situations where you want to also support binding, B<and> allow for
methods such as C<shift>, C<unshift> and related functions.

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/Hash-Agnostic .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: ft=perl6 expandtab sw=4

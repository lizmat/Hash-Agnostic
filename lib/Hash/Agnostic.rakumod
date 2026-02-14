my class X::Hash::NoImplementation is Exception {
    has $.object;
    has $.method;
    method message() {
        my $text = "No implementation of $.method method found for $.object.^name().";
        $*DEFAULT-CLEAN
          ?? "$text\nThis is needed to be able to clear an agnostic hash."
          !! $text
    }
}

role Hash::Agnostic  # UNCOVERABLE
  does Associative  # .AT-KEY and friends
  does Iterable     # .iterator, basically
{

#--- These methods *MUST* be implemented by the consumer -----------------------
    method AT-KEY($) {
        X::Hash::NoImplementation.new(:object(self), :method<AT-KEY>).throw
    }
    method keys() {
        X::Hash::NoImplementation.new(:object(self), :method<keys>).throw
    }

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
        X::Hash::NoImplementation.new(object => self, method => 'BIND-KEY').throw
    }

    method EXISTS-KEY(::?ROLE:D: $key) { self.AT-KEY($key).defined }

    method DELETE-KEY(::?ROLE:D: $) is hidden-from-backtrace {
        X::Hash::NoImplementation.new(:object(self), :method<DELETE-KEY>).throw
    }

    method CLEAR(::?ROLE:D:) {
        my $*DEFAULT-CLEAN := True;
        self.DELETE-KEY($_) for self.keys;
    }

    method ASSIGN-KEY(::?ROLE:D: $key, Mu \value) is raw {
        self.AT-KEY($key) = value;
    }

    method STORE(::?ROLE:D: *@values) {
        self.CLEAR;
        self!STORE(@values);
        self
    }

    method !STORE(@values --> Int:D) {
        my $key;
        my int $keyseen;
        my int $found;

        for @values {
            if $_ ~~ Pair {
                self.ASSIGN-KEY(.key, .value);
                ++$found;
            }
            elsif $_ ~~ Failure {  # UNCOVERABLE
                .throw
            }
            elsif $_ ~~ Map {  # UNCOVERABLE
                $found += self!STORE([.pairs])
            }
            elsif $keyseen {  # UNCOVERABLE
                self.ASSIGN-KEY($key, $_);
                ++$found;  # UNCOVERABLE
                $keyseen = 0;
            }
            else {
                $key := $_;  # UNCOVERABLE
                $keyseen = 1;
            }
        }

        $keyseen
          ?? X::Hash::Store::OddNumber.new(:$found, :last($key)).throw
          !! $found
    }

#--- Hash methods that *MAY* be implemented by the consumer -------------------
    method new(::?CLASS:U: **@values is raw) {
        my $self := self.bless(|%_);
        $self.STORE(@values, :initialize) if @values;
        $self
    }
    method iterator(::?ROLE:D:) { self.pairs.iterator }

    method elems(::?ROLE:D:)   { self.keys.elems }
    method Numeric(::?ROLE:D:) { self.elems      }
    method Int(::?ROLE:D:)     { self.elems      }
    method Bool(::?ROLE:D:)    { so self.elems   }
    method end(::?ROLE:D:)     { self.elems - 1  }

    method values(::?ROLE:D:) {
        self.keys.map: { self.AT-KEY($_) }
    }
    method pairs(::?ROLE:D:) {
        self.keys.map: { Pair.new($_, self.AT-KEY($_) ) }
    }
    method antipairs(::?ROLE:D:) {
        self.keys.map: { Pair.new(self.AT-KEY($_), $_ ) }
    }
    method kv(::?ROLE:D:) {
        Seq.new( KV.new( :backend(self), :iterator(self.keys.iterator ) ) )
    }

    method list(::?ROLE:D:)  {  List.from-iterator(self.iterator) }
    method Slip(::?ROLE:D:)  {  Slip.from-iterator(self.iterator) }
    method List(::?ROLE:D:)  {  List.from-iterator(self.iterator) }
    method Array(::?ROLE:D:) { Array.from-iterator(self.iterator) }
    method Hash(::?ROLE:D:)  {  Hash.new(self) }

    method append(::?ROLE:D: +@values is raw) { self!append(@values) }
    method push(::?ROLE:D:  **@values is raw) { self!append(@values) }

    method !append(@values) {
        my $key;
        my int $keyseen;
        my int $found;

        sub PUSH-KEY($key, $value) {
            if self.EXISTS-KEY($key) {
                my $current := self.AT-KEY($key);
                if $current ~~ Array {
                    $current.push($value);
                }
                else {
                    self.ASSIGN-KEY($key, [$current, $value])
                }
            }
            else {
                self.ASSIGN-KEY($key, $value);
            }
            ++$found;
        }

        for @values {
            if $_ ~~ Pair {
                PUSH-KEY(.key, .value);
            }
            elsif $_ ~~ Failure {  # UNCOVERABLE
                .throw
            }
            elsif $_ ~~ Map {  # UNCOVERABLE
                $found += self!append([.pairs])
            }
            elsif $keyseen {  # UNCOVERABLE
                PUSH-KEY($key, $_);
                $keyseen = 0;
            }
            else {
                $key := $_;  # UNCOVERABLE
                $keyseen = 1;
            }
        }

        $keyseen
          ?? X::Hash::Store::OddNumber.new(:$found, :last($key)).throw
          !! self
    }

    proto method gist(|) {*}
    multi method gist(::?ROLE:U:) { self.Mu::gist }
    multi method gist(::?ROLE:D:) {
        '{' ~ self.pairs.sort( *.key ).map( *.gist).join(", ") ~ '}'
    }

    proto method Str(|) {*}
    multi method Str(::?ROLE:U:) { self.Mu::Str }
    multi method Str(::?ROLE:D:) {
        self.pairs.sort( *.key ).join(" ")
    }

    method perl(::?ROLE:) is DEPRECATED("raku") { self.raku }  # UNCOVERABLE

    proto method raku(|) {*}
    multi method raku(::?ROLE:U:) { self.^name }
    multi method raku(::?ROLE:D:) {
        self.rakuseen(self.^name, {
          ~ self.^name
          ~ '.new('
          ~ self.pairs.sort( *.key ).map({$_<>.raku}).join(',')
          ~ ')'
        })
    }
}

# vim: expandtab shiftwidth=4

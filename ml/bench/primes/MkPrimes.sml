functor MkPrimes (Seq: SEQUENCE) =
struct

  fun primes' n =
    if n < 2 then
      Seq.empty ()
    else
      let
        val sqrt = Real.floor (Math.sqrt (Real.fromInt n))
        val sqrtPrimes = primes' sqrt

        fun multiples i =
          Seq.tabulate (fn j => (j+2)*i) (n div i - 1)
        val composites = Seq.flatten (Seq.map multiples sqrtPrimes)

        (** Note: for some reason, it makes a *big* difference here (I've
          * measured as much as 50% performance improvement) to use Word8s
          * instead of booleans. The compiler must be doing something funky.
          *)
        val flags =
          Seq.inject (Seq.tabulate (fn _ => 0w1: Word8.word) (n+1),
                      Seq.map (fn m => (m, 0w0)) composites)

        fun isPrime i = (Seq.nth flags i = 0w1)
      in
        Seq.filter isPrime (Seq.tabulate (fn i => i+2) (n-1))
      end

  fun primes n =
    Seq.toArraySeq (primes' n)

end

structure CLA = CommandLineArgs
structure Seq = ArraySequence

(* chosen by subdirectory *)
structure Primes = Primes

val n = CLA.parseInt "n" (1000 * 1000 * 100)

fun task () =
  Primes.primes n

val result = Benchmark.run "primes" task
val _ = print ("primes " ^ Int.toString (Seq.length result) ^ "\n")

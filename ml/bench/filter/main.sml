structure CLA = CommandLineArgs
structure Seq = ArraySequence
structure DS = DelayedSeq

(* chosen by subdirectory *)
structure Filter = Filter

val n = CLA.parseInt "n" (1000 * 1000 * 100)
val doCheck = CLA.parseFlag "check"

fun gen i =
  Real.fromInt (i mod 2)

fun keep x =
  Real.== (x, 1.0)

val input = Seq.tabulate gen n

fun task () =
  Filter.filter keep input

fun check result =
  if not doCheck then () else
  let
    val correctLength =
      DS.reduce op+ 0
      (DS.tabulate (fn i => if keep (Seq.nth input i) then 1 else 0) n)

    val correct =
      Seq.length result = correctLength
      andalso
      DS.reduce (fn (a, b) => a andalso b) true
      (DS.tabulate (fn i => Real.== (Seq.nth result i, 1.0)) correctLength)
  in
    if correct then
      print ("correct? yes\n")
    else
      print ("correct? no\n")
  end

val result = Benchmark.run "filter" task
val _ = check result

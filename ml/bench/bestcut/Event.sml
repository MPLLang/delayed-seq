structure Event:
sig
  type t
  val isEnd: t -> bool
  val pos: t -> int
  val value: t -> real

  val generateInput: int -> t Seq.t
end =
struct

  type t = (Word32.word * Real32.real)


  fun r32ToReal (r: Real32.real): real =
    (** Only works when LargeReal = Real. fine for MLton/MPL. *)
    Real32.toLarge r

  fun pos (e: t) = Word32.toInt (#1 e)
  fun value (e: t) = r32ToReal (#2 e)

  fun isEnd (e: t) =
    0w1 = Word32.andb (#1 e, 0w1)

  fun generateInput n =
    let
      val events = ForkJoin.alloc (2*n)
      fun upd i x = Array.update (events, i, x)
    in
      ForkJoin.parfor 10000 (0, n) (fn i =>
        ( upd (i div 2) (Word32.fromInt i, Real32.fromInt i)
        ; upd (i div 2 + 1) (Word32.fromInt i, Real32.fromInt (i+1))
        )
      );
      ArraySlice.full events
    end

end

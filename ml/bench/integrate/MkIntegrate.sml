functor MkIntegrate (Seq : SEQUENCE) =
struct

  fun integrate f (s, e) n =
    let
      val delta = (e-s)/(Real.fromInt n)
      val s' = s + delta/2.0
      val X = Seq.tabulate (fn i => f(s' + (Real.fromInt i) * delta)) n
    in
      (Seq.reduce op+ 0.0 X) * delta
    end

end

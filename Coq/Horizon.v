Require Import Denotational.
Require Import Tactics.

(* Definition of contract horizon and proof of its correctness. *)

Fixpoint horizon (c : contract) : nat :=
  match c with
      | Zero => 0
      | TransfOne _ _ _ => 1
      | Scale _ c' => horizon c'
      | Transl l c' => l + horizon c'
      | Both c1 c2 => max (horizon c1) (horizon c2)
      | IfWithin _ l c1 c2 => l + max (horizon c1) (horizon c2)
  end.

Lemma horizon_empty c rho i : horizon c  <= i -> C[|c|]rho i = None \/ C[|c|]rho i = empty_trans.
Proof.
  generalize dependent rho. generalize dependent i. 
  induction c; simpl in *; intros.
  - auto.
  - destruct i. inversion H. auto.
  - unfold scale_trace, compose, scale_trans. eapply IHc in H. destruct H. 
    + left. rewrite H. apply option_map2_none.
    + destruct (R[|r|](fst rho)). 
      * right. rewrite H. apply scale_empty_trans. 
      * left. reflexivity.
  - assert (horizon c <= i - n) as H' by omega.
    eapply IHc in H'. 
    unfold delay_trace. assert (leb n i = true) as L. apply leb_correct. omega. rewrite L.
    destruct H'; eauto.
  - rewrite NPeano.Nat.max_lub_iff in H. destruct H as [H1 H2].
    eapply IHc1 in H1. eapply IHc2 in H2. unfold add_trace, add_trans. destruct H1.
    left. rewrite H. reflexivity. destruct H2.
    left. rewrite H0. apply option_map2_none.
    rewrite H0, H. right. simpl. unfold empty_trans. f_equal. unfold add_trans'. 
    unfold empty_trans'. rewrite Rplus_0_l. reflexivity.
  - rewrite <- Max.plus_max_distr_l in H.
    rewrite NPeano.Nat.max_lub_iff in H. destruct H as [H1 H2].
    generalize dependent rho. generalize dependent i. 
    induction n; intros.
    + eapply IHc1 in H1. eapply IHc2 in H2.
      simpl. destruct (B[|b|]rho).
      * destruct b0; eassumption.
      * left. reflexivity.
    + simpl. destruct (B[|b|]rho); auto. destruct b0.
      * apply IHc1. omega.
      * unfold delay_trace. 
        assert (leb 1 i = true) as L. apply leb_correct. omega.
        rewrite L. apply IHn; omega.      
Qed.

Theorem horizon_sound c rho i : horizon c  <= i -> C[|c|]rho i ⊆ empty_trans.
Proof.
  simpl. intros R t T. apply horizon_empty with (rho:=rho) in R. destruct R as [R|R].
  tryfalse. rewrite <- R. assumption.
Qed.
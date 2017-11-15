Require Import GraphBasics.Graphs.
Require Import GraphBasics.Paths.



Section Edge_related.

Lemma E_eq2 : forall (e1 e2 : Edge),
  E_eq e1 e2 -> E_eq e2 e1.
Proof.
  intros e1 e2 eq.
  inversion eq.
  apply E_refl.
  apply E_rev.
Qed.

Lemma E_rev_cons: forall(u:Edge)(el:E_list),
  E_reverse (u :: el) = (E_reverse el) ++ (E_reverse (u :: nil)).
Proof.
  intros u el.
  induction el.
  simpl.
  reflexivity.
  destruct u.
  destruct a.
  unfold E_reverse.
  reflexivity.
Qed.

Lemma E_rev_in2: forall (x y : Vertex) (el : E_list),
  In (E_ends x y) (E_reverse el) -> In (E_ends y x) el.
Proof.
  intros x y el i.
  induction el.
  simpl in i.
  inversion i.

  destruct a.
  simpl.
  simpl in i.
  apply in_app_or in i.
  destruct i.
  right.
  apply IHel.
  apply H.
  left.
  unfold In in H.
  destruct H.
  inversion H.
  reflexivity.
  inversion H.
Qed.

Lemma E_rev_in: forall (u: Edge) (x y : Vertex) (el : E_list),
(forall v:Edge, In v el -> ~ E_eq v (E_ends x y)) -> In u (E_reverse el) -> ~ E_eq u (E_ends y x).
Proof.
  intros u x y el vv uu.
  unfold not.
  intros.
  destruct u.
  apply E_rev_in2 in uu.
  apply vv in uu.
  inversion H.
  rewrite H2 in uu.
  rewrite H3 in uu.
  assert (E_eq (E_ends x y) (E_ends x y)).
  apply E_refl.
  apply uu in H1.
  inversion H1.
  rewrite H3 in uu.
  rewrite H4 in uu.
  assert (E_eq (E_ends y x) (E_ends x y)).
  apply E_rev.
  apply uu in H0.
  inversion H0.
Qed.

Lemma E_rev_len: forall(el:E_list),
  length (E_reverse el) = length el.
Proof.
  intros el.
  induction el.
  reflexivity.
  destruct a.
  simpl.
  rewrite app_length.
  simpl.
  rewrite IHel.
  apply plus_comm.
Qed.

Definition E_ends_at_y (v: Vertex) (e: Edge) :=
  match e with
  (E_ends x y) =>  y = v
  end.

End Edge_related.
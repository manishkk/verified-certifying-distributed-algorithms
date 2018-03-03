
Require Import GraphBasics.Graphs.
Require Import Coq.Logic.Classical_Prop.
Require Import Verdi.Verdi.

Require Export StructTact.Fin.

Require Import ExtrOcamlBasic.
Require Import ExtrOcamlNatInt.

Require Import Verdi.ExtrOcamlBasicExt.
Require Import Verdi.ExtrOcamlList.

Require Import FunInd.

Load CDAInterface. 


Section ConnectedChecker.


(* All components are already indexed by natural numbers via GraphBasics. *)
Definition Component_Index := nat.
(* A distance for how long a message has traveled to the recipient. *)
Definition Distance := nat.


(* This is the content of a message. It consists of:
  - var 
  - local leader for the var
  - distance from where it was sent (the temporary local leader)
  - last sender, so that the receiving node can make a parent towards the temporary local leader
*)
Inductive Msg := leader : (Var * Component_Index * Distance * Name) -> Msg.

Definition Msg_eq_dec : forall x y : Msg, {x = y} + {x <> y}.
Proof.
Admitted.
(* Proof.
  intros x y.
  decide equality.
  destruct p.
  destruct p0.
  assert (H1: {n = n0} + {n <> n0}).
  apply Nat.eq_dec.
  destruct H1.
  rewrite e.
  assert (H2: {v0 = v1} + {v0 <> v1}).
  (* This worked because Var was nat before *)
  unfold Nat in *.
  apply Nat.eq_dec.
  destruct H2.
  left.
  rewrite e0.
  reflexivity.
  right.
  intuition.
  inversion H.
  intuition.
  right.
  intuition.
  inversion H.
  intuition.
Qed.
 *)
Record Data := mkData{
  checkerknowledge: Checkerknowledge; 
  checkerinput : Checkerinput;
  leaders : list Msg
}.

(* all components first are their own leader for all fact_vars *)
Fixpoint init_leader_list (n:Name) (c: Certificate) :=
  match c with
  | [] => []
  | hd :: tl => (leader (assignment_var hd, component_index (name_component n), 0, n)) :: init_leader_list n tl
  end.

(* initialization of the network *)
Definition init_Data (me: Name) := 
  mkData (init_Checkerknowledge me) (init_Checkerinput me) (init_leader_list me (certificate (init_Checkerinput me))).


Definition set_leaders a v := mkData (checkerknowledge a) (checkerinput a) v.

Fixpoint sendlist (neighbors: list Component) (new_l: Msg): list (Name * Msg)  :=
  match neighbors with 
    | nil => []
    | hd :: tl => (Checker hd, new_l) :: (sendlist tl new_l)
  end.

(* The component sends itself as the leader for all its fact_vars to all its neighbours *)
Fixpoint initial_send_list (me : Name) cert neighbours: list (Name * Msg) :=
  match cert with
    | [] => []
    | hd :: tl => sendlist neighbours (leader ((assignment_var hd), component_index (name_component me), 0, me)) ++ initial_send_list me tl neighbours
  end.

(* This input starts a checker *)
Inductive Input := alg_terminated : Input.

(* kann weggelassen werden? *)
Definition Output := Msg.


(* eigentlich muss noch irgendwo eine Pr\u00fcfung rein, dass certificate zu var_l passt, denn sonst kann der Algorithmus den Checker betr\u00fcgen... *)
Definition InputHandler (me : Name) (c : Input) (state: Data) :
            (list Output) * Data * list (Name * Msg) := 
	match me  with
    | Checker x => let myneighbours := (neighbors v a g x) in
                     ([] , (mkData (checkerknowledge state) (checkerinput state) (leaders state)), initial_send_list me (certificate(* das hier m\u00fcsste var_l sein oder eine Pr\u00fcfung beinhalten *) (checkerinput state)) myneighbours)
    end.

Fixpoint find_leader (k : nat) (leaders : list Msg) : option nat :=
  match leaders with
  | [] => None
  | leader (var, ind, dis, par) :: tl => if beq_nat k var
                            then Some ind
                            else find_leader k tl
  end.

Definition get_leader_index k (leaders: list Msg) : nat :=
  match (find_leader k leaders) with
  | Some x => x
  | None => 0
  end.

Fixpoint set_leader var n d p (ls: list Msg) : list Msg :=
  match ls with
  | [] => [leader (var, n, d, p)]
  | leader (k, ind, dis, par) :: tl => if beq_nat k var
                                 then leader (k, n, dis, par) :: tl
                                 else set_leader var n d p tl
  end.


Notation "a =/= b" := (beq_nat (Some a) (Some b)) (at level 70).
Notation "a == b" := (beq_nat a b) (at level 70).

Lemma beq_false_nat : forall n m : nat, 
  n <> m -> (n == m) = false.
Proof.
  induction n; induction m; intros.
  intuition.
  intuition.
  intuition.
  simpl.
  intuition.
Qed.
  

Lemma set_leader_sets_leader: forall var n (ls: list Msg) d p,
    n = get_leader_index var (set_leader var n d p ls).
Proof.
  intros var n ls d p.
  induction ls.
    destruct var.
    simpl.
    unfold get_leader_index.
    reflexivity.
    simpl.
    unfold get_leader_index.
    unfold find_leader.
    simpl.
    rewrite <- beq_nat_refl.
    reflexivity.

    destruct a0.
    destruct p0.
    destruct p0.
    destruct p0.
    assert (v0 = var \/ v0 <> var).
    apply classic.
    destruct H.
  
    rewrite H.
    simpl.
    rewrite Nat.eqb_refl.
    unfold get_leader_index.
    simpl.
    rewrite Nat.eqb_refl.
    reflexivity.

    assert(v0 == var = false).
    apply beq_false_nat.
    intuition.
    simpl.
    rewrite H0.
    apply IHls.
Qed.

Fixpoint cert_has_var (vl : list Var) (v : Var) : bool :=
  match vl with
  | nil => false
  | hd :: tl => beq_nat hd v && cert_has_var tl v
  end.

(* 

  Theorem: F\u00fcr jeden a-Teilgraph T gilt: in jeder Zusammenhangskomponente K von T gibt es genau einen Leader, der Teil von K ist.

  Invarianten: Nachrichten k\u00f6nnen nur eine Komponente au\u00dferhalb des a-Teilgraphen geschickt werden
  Invarianten: Von allen Komponenten, die man gesehen hat, nimmt man die "h\u00f6chst"-m\u00f6gliche.

  Lemma: Man nimmt nie einen kleineren Leader, als man schon hat.
  Lemma: Man nimmt nur einen Leader von alpha, wenn alpha Teil vom Zeugen des Leaders ist.
  Lemma: Man kann keine Komponente als Leader w\u00e4hlen, wenn der "Zeugenschnitt" mit der Komponente leer ist.
  
*)

Definition NetHandler (me : Name) (src: Name) (le : Msg) (state: Data) : 
    (list Output) * Data * list (Name * Msg) :=
    match le with
      | leader (var, n, d, p)  => if (cert_has_var (var_l (checkerknowledge state)) var) && Nat.ltb (get_leader_index var (leaders state)) n
                                    then ([], set_leaders state (set_leader var n d p (leaders state)), sendlist (neighbor_l (checkerknowledge state)) (leader (var, n, d+1, me)))
                                  else ([], state, [])
   end.



(* a-Komponente: ist eine Komponente c, bei der a in der Liste von Variablen von c vorkommt *)

Inductive SubGraph : V_set -> V_set -> A_set -> A_set -> Set :=
  | SG_empty : forall v a (g: Graph v a), SubGraph V_empty v A_empty a
  | SG_vertex: forall (vSG v : V_set) (aSG a : A_set) x (g: Graph v a),
      ~ vSG x -> v x -> SubGraph vSG v aSG a -> SubGraph (V_union (V_single x) vSG) v aSG a
  | SG_edge : forall (vSG v : V_set) (aSG a : A_set) (x : Arc) v1 v2 (g: Graph v a),
      let x := (A_ends v1 v2) in
      ~ aSG x -> a x -> SubGraph vSG v aSG a -> vSG v1 -> vSG v2 -> SubGraph vSG v (A_union aSG (E_set v1 v2)) a
  | SG_eq: forall vSG vSG' v aSG aSG' a (g: Graph v a),
    vSG = vSG' -> aSG = aSG' -> SubGraph vSG v aSG a -> SubGraph vSG' v aSG' a.


Lemma TotalGraph_isa_SubGraph: forall v a (g: Graph v a), SubGraph v v a a.
Proof.
  intros v a g.
  induction g.
    apply SG_empty. apply G_empty.

    apply (SG_vertex v0 (V_union (V_single x) v0) a0 a0).
    apply G_vertex.
    apply g0. apply n. apply n. apply In_left. apply In_single.

  unfold SubGraph.
  split.
  unfold V_included.
  unfold Included.
  auto.
  split.
  unfold A_included. unfold Included.
  auto.
  split.
  apply (G_ina_inv1 v a g) in H.
  apply H.
  apply (G_ina_inv2 v a g) in H.
  apply H.
Qed.

Lemma EmptyGraph_isa_SubGraph: forall v a g, SubGraph V_empty v A_empty a g.
Proof.
  intros v a g.
  unfold SubGraph.
  split ; intros.
  unfold V_included. unfold Included. intros.
  inversion H.
  unfold A_included. unfold Included. intros.
  split ; intros ; inversion H.
Qed.

Lemma empty_sub_set: forall T vSG, Included T vSG (Empty T) -> vSG = Empty T.
Proof.
  intros.
  apply U_set_eq.
  intros.
  split.
  intros.
  apply (H x H0).
  intros.
  inversion H0.
Qed.

(* Lemma incl_impl_incl_in_less: forall vSG v0 x, (V_included vSG (V_union (V_single x) v0) /\ ~ v0 x) -> V_included vSG v0.
Proof.
  intros.
  unfold V_included in * ; unfold V_union in * ; unfold V_single in *.
  destruct H.
  unfold Included in *.

  intros.
  apply (H x0) in H1.
  
  destruct H1.
  inversion H1.
  rewrite H2 in *.
  admit.
  apply H1.
  

Lemma incl_impl_incl_in_less: forall T vSG v0, Included T vSG (V_union (V_single x) v0) -> V_included vSG v0 *)

Lemma SubGraph_isa_Graph : forall vSG v aSG a g, SubGraph vSG v aSG a g -> Graph vSG aSG.
Proof.
  intros vSG v aSG a g H.
  unfold SubGraph in H.
  destruct H.
  destruct H0.
  induction g.
    apply (empty_sub_set Vertex) in H.
    apply (empty_sub_set Arc) in H0.
    rewrite H ; rewrite H0.
    apply G_empty.

    apply IHg.
    unfold V_union in H.
    unfold V_single in H.
    unfold V_included in H.
    admit.
    apply H0.

    apply IHg.
    apply H.
    admit.

    rewrite e in *; rewrite e0 in *.
    apply IHg.
    apply H ; apply H0.
Admitted.

(* (* a subgraph of g *)
Definition SubGraph (vSG v : V_set) (aSG a : A_set) (g : Graph v a) := 
  V_included vSG v /\
  A_included aSG a /\
  (forall (v1 v2 : Component), let ar := (A_ends v1 v2) in
                                 (aSG ar) -> (vSG v1 /\ vSG v2)).


(* Definition SubGraph (vSG v : V_set) (aSG a : A_set) (g : Graph v a) := 
  (forall (c: Component), vSG c -> v c) /\ 
  (forall (v1 v2 : Component), let ar := (A_ends v1 v2) in
                                 (aSG ar) -> (a ar /\ vSG v1 /\ vSG v2)).
 *)

Lemma TotalGraph_isa_SubGraph: forall v a g, SubGraph v v a a g.
Proof.
  intros v a g.
  unfold SubGraph.
  split.
  unfold V_included.
  unfold Included.
  auto.
  split.
  unfold A_included. unfold Included.
  auto.
  split.
  apply (G_ina_inv1 v a g) in H.
  apply H.
  apply (G_ina_inv2 v a g) in H.
  apply H.
Qed.

Lemma EmptyGraph_isa_SubGraph: forall v a g, SubGraph V_empty v A_empty a g.
Proof.
  intros v a g.
  unfold SubGraph.
  split ; intros.
  unfold V_included. unfold Included. intros.
  inversion H.
  unfold A_included. unfold Included. intros.
  split ; intros ; inversion H.
Qed.

Lemma empty_sub_set: forall T vSG, Included T vSG (Empty T) -> vSG = Empty T.
Proof.
  intros.
  apply U_set_eq.
  intros.
  split.
  intros.
  apply (H x H0).
  intros.
  inversion H0.
Qed.

(* Lemma incl_impl_incl_in_less: forall vSG v0 x, (V_included vSG (V_union (V_single x) v0) /\ ~ v0 x) -> V_included vSG v0.
Proof.
  intros.
  unfold V_included in * ; unfold V_union in * ; unfold V_single in *.
  destruct H.
  unfold Included in *.

  intros.
  apply (H x0) in H1.
  
  destruct H1.
  inversion H1.
  rewrite H2 in *.
  admit.
  apply H1.
  

Lemma incl_impl_incl_in_less: forall T vSG v0, Included T vSG (V_union (V_single x) v0) -> V_included vSG v0 *)

Lemma SubGraph_isa_Graph : forall vSG v aSG a g, SubGraph vSG v aSG a g -> Graph vSG aSG.
Proof.
  intros vSG v aSG a g H.
  unfold SubGraph in H.
  destruct H.
  destruct H0.
  induction g.
    apply (empty_sub_set Vertex) in H.
    apply (empty_sub_set Arc) in H0.
    rewrite H ; rewrite H0.
    apply G_empty.

    apply IHg.
    unfold V_union in H.
    unfold V_single in H.
    unfold V_included in H.
    admit.
    apply H0.

    apply IHg.
    apply H.
    admit.

    rewrite e in *; rewrite e0 in *.
    apply IHg.
    apply H ; apply H0.
Admitted. *)

End ConnectedChecker.
;; Milestone Crowdfunding (Clarity v2)
;; - Create campaigns with a funding goal and deadline.
;; - Creator adds fixed milestones whose sum must equal the goal.
;; - Backers pledge STX into escrow (contract balance).
;; - For each milestone, backers approve; creator withdraws on majority.
;; - If the goal is not met by the deadline, backers can refund.
;; ------------------------------------------------------------

(define-constant ERR-BAD-PARAMS u1)
(define-constant ERR-CAMPAIGN-NOT-FOUND u2)
(define-constant ERR-NOT-ACTIVE u3)
(define-constant ERR-DEADLINE u4)
(define-constant ERR-NO-FUNDS u5)
(define-constant ERR-GOAL-NOT-MET u6)

(define-data-var next-campaign-id uint u0)

(define-map campaigns
  {id: uint}
  {creator: principal, goal: uint, pledged: uint, deadline: uint, active: bool, failed: bool})

(define-map pledges
  {campaign-id: uint, backer: principal}
  {amount: uint})

(define-map milestone-meta
  {campaign-id: uint}
  {count: uint, total: uint, target: uint})

(define-map backer-stats
  {campaign-id: uint}
  {backers: uint})

(define-private (get-pledge (id uint) (backer principal))
  (default-to {amount: u0} (map-get? pledges {campaign-id: id, backer: backer})))

(define-private (get-backer-count (id uint))
  (default-to {backers: u0} (map-get? backer-stats {campaign-id: id})))

;; Get the contract principal (recipient for escrowed STX)
(define-read-only (self)
  (as-contract tx-sender))

;; Existing code starts here
(define-public (create-campaign (goal uint) (deadline uint) (target-milestones uint))
  (begin
    (asserts! (> goal u0) (err ERR-BAD-PARAMS))
    ;; Check deadline is in the future
    (asserts! (> deadline burn-block-height) (err ERR-BAD-PARAMS))
    (asserts! (> target-milestones u0) (err ERR-BAD-PARAMS))
    (let
      (
        (id (var-get next-campaign-id))
      )
      (var-set next-campaign-id (+ id u1))
      (map-set campaigns {id: id}
        { creator: tx-sender, goal: goal, pledged: u0, deadline: deadline, active: true, failed: false })
      (map-set milestone-meta {campaign-id: id}
        { count: u0, total: u0, target: target-milestones })
      (map-set backer-stats {campaign-id: id} { backers: u0 })
      (ok id)
    )))


(define-public (pledge (id uint) (amount uint))
  (let
    (
      (c (map-get? campaigns {id: id}))
    )
    (begin
      (asserts! (is-some c) (err ERR-CAMPAIGN-NOT-FOUND))
      (let
        (
          (C (unwrap-panic c))
        )
        (asserts! (get active C) (err ERR-NOT-ACTIVE))
        (asserts! (> amount u0) (err ERR-BAD-PARAMS))
        ;; Check if deadline has not passed
        (asserts! (<= burn-block-height (get deadline C)) (err ERR-DEADLINE))
        ;; Transfer STX from backer to contract escrow
        (match (stx-transfer? amount tx-sender (self))
          ok (let
                (
                  (prev (get-pledge id tx-sender))
                  (first-time (is-eq (get amount prev) u0))
                  (new-pledged (+ (get pledged C) amount))
                )
                (begin
                  (map-set campaigns {id: id}
                    { creator: (get creator C)
                    , goal: (get goal C)
                    , pledged: new-pledged
                    , deadline: (get deadline C)
                    , active: (get active C)
                    , failed: (get failed C) })
                  (map-set pledges {campaign-id: id, backer: tx-sender}
                    { amount: (+ (get amount prev) amount) })
                  (if first-time
                      (let ((bs (get-backer-count id)))
                        (map-set backer-stats {campaign-id: id}
                          { backers: (+ (get backers bs) u1) })
                        (ok true))
                      (ok true))
                ))
          err (err ERR-NO-FUNDS))
      ))))


(define-public (finalize-failed (id uint))
  (let ((c (map-get? campaigns {id: id})))
    (begin
      (asserts! (is-some c) (err ERR-CAMPAIGN-NOT-FOUND))
      (let ((C (unwrap-panic c)))
        (asserts! (get active C) (err ERR-NOT-ACTIVE))
        ;; Check if deadline has passed
        (asserts! (> burn-block-height (get deadline C)) (err ERR-DEADLINE))
        (asserts! (< (get pledged C) (get goal C)) (err ERR-GOAL-NOT-MET))
        (map-set campaigns {id: id}
          { creator: (get creator C)
          , goal: (get goal C)
          , pledged: (get pledged C)
          , deadline: (get deadline C)
          , active: false
          , failed: true })
        (ok true)))))

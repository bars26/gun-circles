# Gün: savings circles on gno.land

_Altın günü, on chain._

A **rotating savings circle** is how hundreds of millions of people save without a bank. A group of
friends pays the same amount every round, and each round the whole pot goes to one of them, in
turn, until everyone has had it once. In Turkey it is the *altın günü* (the "gold day"); elsewhere
it is a *tanda*, *susu*, *chit fund*, *hui* or *tontine*.

It works on trust, and it breaks on trust: the organizer holds the cash, nobody can see who paid,
and the members who receive the pot early can simply stop paying. **Gün** puts the circle in a
gno.land realm, so the coins sit with the code, the books are public, and the rules are enforced
instead of remembered.

- **Demo video (2:35):** https://youtu.be/jq515jJL9PM
- **Live on the Onyx testnet:** https://latest.testnets.gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun
- **Rules package:** `gno.land/p/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/rosca`
- **Realm:** `gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun`

## How a circle works

1. **Create.** The organizer picks a name, the contribution per round, the round length, how many
   contributions of collateral each member locks, a join window, and the members in turn order.
   The organizer must be one of the members.
2. **Join.** Every listed member joins by sending exactly the collateral. Nobody is in a circle
   they did not join; an invitation alone does not put a circle on your page. The last join starts
   round 1.
3. **Pay.** Each round every member pays the contribution (the round's recipient too, as in a real
   *gün*). When the last payment arrives the pot is credited to the recipient. Paying after the due
   time still works until someone settles the round, and is marked **late**.
4. **Settle.** Once a round is overdue, anyone can close it. A member who has not paid is covered
   from their own collateral (marked **covered**). The schedule does not drift: round *r* is always
   due at `start + r × period`.
5. **Withdraw.** Pots, refunds and released collateral are credited, never pushed. Each member
   withdraws what they are owed.

Members can also **swap turns** by mutual consent (one proposes, the other accepts) as long as both
turns are still ahead.

## What it guarantees, and what it does not

| Collateral per member | What happens |
|---|---|
| *members − 1* contributions | **Fully secured.** Nobody can run out of collateral, so every member is guaranteed the full pot. |
| fewer | Covers that many missed payments per member. One more and the circle **breaks**. |
| none | Runs on trust: the first missed payment breaks the circle. |

When a circle breaks it winds down without anyone deciding who gets what:

- this round's pot never formed, so everyone who paid this round gets that payment back, and
  covers taken from collateral this round are undone;
- honest members get their remaining collateral back;
- anything the defaulter has **not withdrawn yet** (typically the pot they already received) is
  used to repay honest members who paid in more than they received, in proportion to that
  shortfall, up to the shortfall; whatever is left goes back to the defaulter.

What a defaulter **already withdrew** cannot be recovered by any contract without credit or
identity, and Gün does not pretend otherwise: the page says how many missed payments the circle can
absorb before anyone is at risk, and the organizer chooses that number.

## Design

```
p/rosca   pure state machine: no coins, no chain calls, time passed in
r/gun     holds the coins, checks payments, renders the pages
```

`rosca` can be imported by any realm that wants a savings circle with different custody, tokens or
front end. It never touches coins: callers pass in who acted, how much they sent and the current
time, and must keep the coins they hold equal to `Circle.Held()`.

Security notes, following the gno.land security guide and AI contract-review checklist:

- **Payments** are accepted only from a direct user call: `cur.Previous().IsUserCall()` is paired with
  `unsafe.OriginSend()`, so an intermediate realm or a `maketx run` script cannot spend the
  envelope and still pass the amount check. Only `ugnot` is accepted, so no other denom can get
  stuck.
- **Caller identity** comes from `cur.Previous()`, never from an address parameter.
- **No pointer** to stored state ever leaves the realm; views return copies.
- **Render** passes every user-supplied string (circle names) through `sanitize.InlineText`, and
  rejects malformed ids and addresses.
- **Bounded work.** Circles have 2 to 12 members; every loop is over members or rounds of one
  circle. Lists are paged (10 per page). A member page lists at most 200 circles, and only circles
  the member created or joined.
- **Books in the open.** The home page shows what the circles account for next to what the realm
  actually holds, and says so loudly if the realm ever holds less.
- **Amounts.** Contributions are capped at 1,000,000 GNOT; shares use a 128-bit multiply-divide.

## Try it

Create a circle from the [Actions](https://latest.testnets.gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun$help&func=Create)
tab (Adena wallet), or with `gnokey`:

```bash
gnokey maketx call -pkgpath gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun \
  -func Create -args "Salı günü" -args 100000 -args 604800 -args 2 -args 259200 \
  -args "g1you...,g1friend...,g1another..." \
  -gas-fee 35000ugnot -gas-wanted 30000000 -broadcast \
  -chainid onyx-1 -remote https://rpc.latest.testnets.gno.land:443 YOURKEY
```

Each circle page links its actions with the right amount pre-filled, for example
`…/gun$help&func=Pay&id=1&.send=100000ugnot`.

`scripts/demo.sh testnet` runs a whole three-member circle with demo keys: everyone joins with two
rounds of collateral, Zeynep skips round 2 and is covered from collateral, and everyone withdraws
at the end.

## Verified on the testnet

Circle [#1 "Salı günü"](https://latest.testnets.gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun:c/1)
ran end to end on Onyx (`onyx-1`) on 2026-11-26 with `scripts/demo.sh testnet`: three members,
0.1 GNOT per round, 2 rounds of collateral (fully secured), 60-second rounds. Zeynep skipped
round 2 and was covered from her collateral; everyone withdrew 0.3 GNOT of pots plus their
released collateral, and the realm's books ended at 0 held, 0 owed. The round marks read `PLL`,
`LLC`, `LLL`: with 60-second rounds most payments landed after the due time, which is exactly what
the late marks are for.

| Step | Transaction |
|---|---|
| Deploy `p/rosca` | `UtY4XMwPnnV6D/7k7jK2rS8pyFUGrORNjq+whRWrnU0=` (height 1413164) |
| Deploy `r/gun` | `Xp2Egwka8qCllYeHdz/E50Tf2RtOepPvMqB8c5dHbqA=` (height 1413167) |
| Create circle | `Dq2cWpimRuJ/L4uNwi94QlFzV8NFgrwbDhX4M/BqPIg=` |
| Joins (Ayşe, Mehmet, Zeynep) | `ocYv1rTIZvkKX8tAwexZmN18tjJmpOMM5yTK1A7tlPk=`, `pnYqtXjr+CxTNo2DA4NFGKNyI6bnmixLyOuIsCIdiiM=`, `n5wFVBft3Fq+b1F4kPOmOdBJf77Hb3Fsnifwv2Ys4lA=` |
| Round 2 settled, Zeynep covered | `efKMzmzdqtVJkULEYuelXzKQS/gjupIrePHw+w/qZ8U=` |
| Withdrawals | `wgQVgb2ac20D8Sx1Rnz/NNfDVd2LYxRQmrmlGdRcBOE=`, `9pWaB2hqh40H4kcfos/wAgFLShQ0LnDPy+OpW+eSxHI=`, `8CHyWNvQ8EMEglOX7wBwtkFO6FdLs80Rzj7r8q1sBb4=` |

The full log, with every payment, is in [`docs/testnet-run.log`](docs/testnet-run.log).

Circle [#2 "Cuma günü"](https://latest.testnets.gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun:c/2),
recorded for the demo video, used 10-minute rounds and one round of collateral. Every payment
was on time (`PPP`, `PPC`, `PPP`): Zeynep skipped round 2, Mehmet settled it once it was overdue
(`TCt/qsyyRzV/k/W7j/74gZc0nhROyV3o6wxxHRJoGlc=`) and her collateral covered it. Ayşe and Mehmet
withdrew 0.4 GNOT each (pot plus released collateral), Zeynep 0.3 GNOT (pot only, her collateral
was used).

## Develop

Needs the gno toolchain (`gno`, `gnokey`, `gnodev`).

```bash
gno test ./p/rosca ./r/gun     # 22 tests
gnodev local                   # local chain + gnoweb at http://127.0.0.1:8888
./scripts/demo.sh local        # full circle against gnodev
```

The package tests keep a ledger of every coin in and out and check after every step that it equals
`Held()`: a full circle, late payments, covers, breaks with and without an unwithdrawn pot, the
proportional split, swaps, cancellations and every validation error.

## License

MIT

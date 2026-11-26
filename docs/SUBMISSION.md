# DoraHacks submission: Gnome Tavern Hackathon

**Name:** Gün: savings circles on gno.land

**Track:** Default Track

**Tags:** Crypto / Web3, DeFi, Social

**One-line description**

Rotating savings circles (the Turkish "altın günü") in a gno.land realm: members lock collateral, pay each round, and the pot goes to each in turn, with missed payments covered and the books in the open.

**Links**

- Live on the testnet (Onyx, onyx-1): https://latest.testnets.gno.land/r/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/gun
- Rules package: https://latest.testnets.gno.land/p/g1k0pgsw39lh0a6mama0qh0lxa6vphd4yc2w9gqw/rosca
- Code (MIT): https://github.com/bars26/gun-circles
- Demo video: https://youtu.be/jq515jJL9PM

**Description**

A rotating savings circle is how hundreds of millions of people save without a bank. A group of friends pays the same amount every round, and each round the whole pot goes to one of them, in turn, until everyone has had it once. In Turkey it is the *altın günü*; elsewhere a tanda, susu, hui or chit fund. It runs on trust and it breaks on trust: the organizer holds the cash, nobody can see who paid, and whoever gets the pot early can stop paying.

Gün puts the circle in a realm, so the coins sit with the code and the rules are enforced instead of remembered.

- **Everyone joins on purpose.** The organizer lists the members in turn order; each one joins by locking collateral. An invitation alone puts nobody in a circle.
- **Collateral covers missed payments.** Once a round is overdue, anyone can settle it, and a member who did not pay is covered from their own collateral. With *members − 1* rounds of collateral a circle is fully secured: every member is guaranteed the full pot. The circle page states how much risk a circle carries before anyone joins.
- **A broken circle winds down by rule.** This round's payments are refunded, honest members get their collateral back, and a defaulter's unwithdrawn pot repays honest members who are short.
- **Payouts are pulled, not pushed**, and every payment is marked on time, late, covered or missed, round by round.
- **Open books.** The home page shows what the circles owe next to what the realm holds.

**How it is built**

- `p/rosca` is a pure state machine with no coins and no chain calls, so any realm can reuse it. `r/gun` holds the coins, checks payments and renders the pages in gnoweb, with action links that pre-fill the amount to send.
- Payments follow the gno security guide: `cur.Previous().IsUserCall()` paired with `OriginSend`, so a wrapper realm or a `maketx run` script cannot fake a payment; only ugnot is accepted; caller identity comes from `cur.Previous()`; no pointer to stored state leaves the realm; circle names go through `sanitize.InlineText`; every loop is bounded (2 to 12 members, paged lists).
- 22 tests. The package tests keep a ledger of every coin in and out and check after every step that it matches what the realm must hold. CI runs `gno lint` and `gno test` with gno v1.8.0.

**Verified on the testnet**

Two circles have run end to end on Onyx: #1 "Salı günü" (1-minute rounds, fully secured) and #2 "Cuma günü" (10-minute rounds, one round of collateral), each with a missed payment covered from collateral, every member withdrawing, and the books ending at 0 held, 0 owed. Transaction hashes are in the README.

**What is next (retention)**

Mainnet deployment; GRC20 contributions next to ugnot; optional fair turn order by commit-reveal draw; reminders and a per-member reliability history that circles can require before someone joins.

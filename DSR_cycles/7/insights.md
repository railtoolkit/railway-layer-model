
# resource layer

  * segment id for reference needed

# transit layer

  * enable blocking time and headway time
    * switch from signal to signal based occupation time to clearing point to clearing point based occupation time
      * decribed in P.114  Pachl:2002 3.edition - no longer included in higher editions
    * trigger/braking point still oriented towards signals
  * cases: pass, run-start, run-end, route-begin, route-extend
    * minimal snippets might be combined
    * edge cases: (swinging) overlap
  * take resource boundery from resource layer
    * push or pull
    * push suiteable for run-start
    * pull suiteable for route-extend

DEFINE (ELIZA
+==============================================================================
+ ELIZA (script) = NIL.
+   Seiteneffekt ist eine "Konversation" mit dem Benutzer des Programms,
+   wobei auf eingegebene Sätze (d.h. Listen von Namen) Transformationsregeln
+   des Skripts angewendet werden, um entsprechende "Antworten" zu ermitteln.
+   Inkorrekte Eingaben (z.B. BYE) beenden die Funktionsauswertung.
+
+   Für die Beschreibung der Datenstrukturen und für weitere Anregungen siehe
+     Joseph Weizenbaum: ELIZA - A Computer Program For the Study
+     of Natural Language Communication Between Man And Machine.
+     Communications of the ACM 9 (1966), S. 36 - 45.
+==============================================================================
  (LAMBDA (SCRIPT)
    ((LAMBDA (SENTENCE)
       (COND
         ((ATOMLISTP SENTENCE) (ELIZA (LOOKUP SCRIPT SENTENCE)))
         (T NIL)
     ) )
     (READ)
  ) )
+
       )

DEFINE (LOOKUP
+==============================================================================
+ LOOKUP (script sentence) = script'   mit
+   script  =
+     ((key[1] . rules[1]) ... (key[i] . rules [i]) ... (key[m] . rules[m])),
+   script' =
+     ((key[1] . rules[1]) ... (key[i] . rules'[i]) ... (key[m] . rules[m])),
+   wobei MEMBERP (key[j] sentence) = NIL
+   oder REPLY (rules[j] sentence) = NONE für jedes j < i gilt,
+   sowie MEMBERP (key[i] sentence) = T oder key[i] = NONE
+   und REPLY (rules[i] sentence) = rules'.
+   Das modifizierte Skript für die weitere Konversation ist das Ergebnis, und
+   Seiteneffekt der Funktionsauswertung ist die Ausgabe der Antwort.
+==============================================================================
  (LAMBDA (SCRIPT SENTENCE)
    ((LAMBDA (KEYWORD RULES)
       (COND
         ((OR (MEMBERP KEYWORD SENTENCE) (EQ KEYWORD (QUOTE NONE)))
          ((LAMBDA (RESULT)
             (COND
               ((NOT (EQ RESULT (QUOTE NONE)))
                (CONS (CONS KEYWORD RESULT) (CDR SCRIPT))
               )
               (T (CONS (CAR SCRIPT) (LOOKUP (CDR SCRIPT) SENTENCE)))
           ) )
           (REPLY RULES SENTENCE)
         ))
         (T (CONS (CAR SCRIPT) (LOOKUP (CDR SCRIPT) SENTENCE)))
     ) )
     (CAR (CAR SCRIPT))
     (CDR (CAR SCRIPT))
  ) )
+
       )


DEFINE (REPLY
+==============================================================================
+ REPLY (rules sentence) = rules'   mit
+   rules  = ((d[1] r[1, 1] r[1, 2] ... r[1, m[1]]) ...
+             (d[i] r[i, 1] r[i, 2] ... r[i, m[i]]) ...
+             (d[n] r[n, 1] r[n, 2] ... r[n, m[n]])),
+   rules' = ((d[1] r[1, 1] r[1, 2] ... r[1, m[1]]) ...
+             (d[i] r[i, 2] ... r[i, m[i]] r[i, 1]) ...
+             (d[n] r[n, 1] r[n, 2] ... r[n, m[n]])),
+   wobei DECOMPOSITION (d[j] sentence) = NONE für jedes j < i
+   sowie DECOMPOSITION (d[i] sentence) = match # NONE gilt.
+   Dieses Umsortieren der Regeln soll für Abwechslung sorgen.
+   Seiteneffekt ist die Ausgabe von REASSEMBLY (r[i, 1] match).
+ REPLY (rules sentence) = NONE     falls keine passende Regel existiert.
+==============================================================================
  (LAMBDA (RULES SENTENCE)
    (COND
      ((NULL RULES) (QUOTE NONE))
      (T
       ((LAMBDA (RULE RULES)
          ((LAMBDA (MATCH)
             (COND
               ((EQ MATCH (QUOTE NONE))
                (SCONS RULE (REPLY RULES SENTENCE))
               )
               (T
                ((LAMBDA (DUMMY1 DUMMY2 RESULT) RESULT)
                 (PRINT (REASSEMBLY (CAR (CDR RULE)) MATCH))
                 (NEWLINE)
                 (CONS
                   (CONS
                     (CAR RULE)
                     (APPEND (CDR (CDR RULE)) (LIST (CAR (CDR RULE))))
                   )
                   RULES
                 )
               ))
           ) )
           (DECOMPOSITION (CAR RULE) SENTENCE)
        ) )
        (CAR RULES)
        (CDR RULES)
      ))
  ) )
+
       )

DEFINE (DECOMPOSITION
+==============================================================================
+ DECOMPOSITION (pattern sentence) = match   mit
+   pattern  = (s[1] ... s[m]),
+   sentence = ( w[1, 1] ... w[1, n[1]]  ...  w[m, 1] ... w[m, n[m]] ),
+   match    = ((w[1, 1] ... w[1, n[1]]) ... (w[m, 1] ... w[m, n[m]])),
+   wobei jedes s[i] zu (w[i, 1] ... w[i, n[i]]) paßt, d.h.
+     s[i] ist ein Name und n[i] = 1 und w[i, 1] = s[i], oder
+     s[i] ist eine Liste und n[i] = 1 und MEMBERP (w[i, 1] s[i]) = T, oder
+     s[i] ist eine Zahl und n[i] = s[i], bzw. s[i] = 0 und n[i] >= 0.
+   Im Fall s[i] = 0 wird n[i] mit Hilfe des Backtracking-Verfahrens bestimmt.
+ DECOMPOSITION (pattern sentence) = NONE    falls keine Zerlegung existiert.
+==============================================================================
  (LAMBDA (PATTERN SENTENCE)
    (COND
      ((NULL PATTERN)
       (COND
         ((NULL SENTENCE) NIL)
         (T (QUOTE NONE))
      ))
      ((NUMBERP (CAR PATTERN))
       ((LAMBDA (N)
          (COND
            ((ZEROP N)
             ((LAMBDA (MATCH)
                (COND
                  ((NOT (EQ MATCH (QUOTE NONE))) MATCH)
                  ((NULL SENTENCE) (QUOTE NONE))
                  (T
                   (SCONS2
                     (CAR SENTENCE)
                     (DECOMPOSITION PATTERN (CDR SENTENCE))
                  ))
              ) )
              (SCONS
                NIL
                (DECOMPOSITION (CDR PATTERN) SENTENCE)
              )
            ))
            ((NULL SENTENCE) (QUOTE NONE))
            ((ONEP N)
             (SCONS
               (LIST (CAR SENTENCE))
               (DECOMPOSITION (CDR PATTERN) (CDR SENTENCE))
            ))
            (T
             (SCONS2
               (CAR SENTENCE)
               (DECOMPOSITION (CONS (SUB1 N) (CDR PATTERN)) (CDR SENTENCE))
            ))
        ) )
        (CAR PATTERN)
      ))
      ((NULL SENTENCE) (QUOTE NONE))
      ((OR
         (EQ (CAR SENTENCE) (CAR PATTERN))
         (AND (ATOMLISTP (CAR PATTERN)) (MEMBERP (CAR SENTENCE) (CAR PATTERN)))
       )
       (SCONS
         (LIST (CAR SENTENCE))
         (DECOMPOSITION (CDR PATTERN) (CDR SENTENCE))
      ))
      (T (QUOTE NONE))
  ) )
+
       )


DEFINE (REASSEMBLY
+==============================================================================
+ REASSEMBLY (pattern match) = sentence   mit
+   pattern  = (s[1] ... s[m]),
+   match    = ((v[1, 1] ... v[1, l[1]]) ... (v[k, 1] ... v[k, l[k]])),
+   sentence = ( w[1, 1] ... w[1, n[1]]  ...  w[m, 1] ... w[m, n[m]] ),
+   wobei jedes s[i] die Folge w[i, 1] ... w[i, n[i]] erzeugt, d.h.
+     s[i] ist ein Name und n[i] = 1 und w[i, 1] = s[i], oder
+     s[i] ist eine Zahl von 1 bis k und n[i] = l[s[i]]
+     und w[i, j] = v[s[i], j] für jedes j.
+==============================================================================
  (LAMBDA (PATTERN MATCH)
    (COND
      ((NULL PATTERN) NIL)
      (T
       ((LAMBDA (SYMBOL SENTENCE)
          (COND
            ((NUMBERP SYMBOL) (APPEND (SELECT MATCH SYMBOL) SENTENCE))
            (T (CONS SYMBOL SENTENCE))
        ) )
        (CAR PATTERN)
        (REASSEMBLY (CDR PATTERN) MATCH)
      ))
  ) )
+
       )

DEFINE (SCONS
+==============================================================================
+ SCONS (x y)    = (x . y)   falls y # NONE,
+ SCONS (x NONE) = NONE.
+==============================================================================
  (LAMBDA (X Y)
    (COND
      ((EQ Y (QUOTE NONE)) (QUOTE NONE))
      (T (CONS X Y))
  ) )
+
       )

DEFINE (SCONS2
+==============================================================================
+ SCONS2 (x (y . ys)) = ((x . y) . ys),
+ SCONS2 (x NONE)     = NONE.
+==============================================================================
  (LAMBDA (X YS)
    (COND
      ((EQ YS (QUOTE NONE)) (QUOTE NONE))
      (T (CONS (CONS X (CAR YS)) (CDR YS)))
  ) )
+
       )


DEFINE (APPEND
+==============================================================================
+ APPEND ((x[1] ... x[m]) (y[1] ... y[n])) = (x[1] ... x[m] y[1] ... y[n]).
+==============================================================================
  (LAMBDA (XS YS)
    (COND
      ((NULL XS) YS)
      (T (CONS (CAR XS) (APPEND (CDR XS) YS)))
  ) )
+
       )

DEFINE (ATOMLISTP
+==============================================================================
+ ATOMLISTP ((x[1] ... x[m])) = T     falls x[i] für jedes i ein Atom ist,
+ ATOMLISTP ((x[1] ... x[m])) = NIL   falls x[i] für ein i kein Atom ist,
+ ATOMLISTP (x)               = NIL   falls x keine Liste ist.
+==============================================================================
  (LAMBDA (XS)
    (OR (NULL XS) (AND (NOT (ATOM XS)) (ATOM (CAR XS)) (ATOMLISTP (CDR XS))))
  )
+
       )

DEFINE (MEMBERP
+==============================================================================
+ MEMBERP (x (x[1] ... x[m])) = T     falls x = x[i] für ein i,
+ MEMBERP (x (x[1] ... x[m])) = NIL   falls x # x[i] für jedes i.
+==============================================================================
  (LAMBDA (X XS)
    (AND (NOT (NULL XS)) (OR (EQ X (CAR XS)) (MEMBERP X (CDR XS))))
  )
+
       )

DEFINE (SELECT
+==============================================================================
+ SELECT ((x[1] ... x[m]) n) = x[n].
+==============================================================================
  (LAMBDA (XS N)
    (COND
      ((ONEP N) (CAR XS))
      (T (SELECT (CDR XS) (SUB1 N)))
  ) )
+
       )


ELIZA (
+==============================================================================
  (
   (DEUTSCH
    ((0)
     (I AM SORRY I SPEAK ONLY ENGLISH)
   ))
   (HELLO
    ((0)
     (HOW DO YOU DO PLEASE STATE YOUR PROBLEM)
   ))
   (COMPUTER
    ((0)
     (DO COMPUTERS WORRY YOU)
     (WHY DO YOU MENTION COMPUTERS)
     (WHAT DO YOU THINK MACHINES HAVE TO DO WITH YOUR PROBLEM)
     (DON T YOU THINK COMPUTERS CAN HELP PEOPLE)
     (WHAT ABOUT MACHINES WORRIES YOU)
     (WHAT DO YOU THINK ABOUT MACHINES)
   ))
   (NAME
    ((0)
     (I AM NOT INTERESTED IN NAMES)
     (I VE TOLD YOU BEFORE I DON T CARE ABOUT NAMES PLEASE CONTINUE)
   ))
   (LIKE
    ((0 (AM IS ARE WAS) 0 LIKE 0)
     (IN WHAT WAY)
     (WHAT RESEMBLANCE DO YOU SEE)
     (WHAT DOES THAT SIMILARITY SUGGEST TO YOU)
     (WHAT OTHER CONNECTIONS DO YOU SEE)
     (WHAT DO YOU SUPPOSE THAT RESEMBLANCE MEANS)
     (WHAT IS THE CONNECTION DO YOU SUPPOSE)
     (COULD THERE REALLY BE SOME CONNECTION)
     (HOW)
   ))
   (REMEMBER
    ((0 I REMEMBER 0)
     (DO YOU OFTEN THINK OF 4)
     (DOES THINKING OF 4 BRING ANYTHING ELSE TO MIND)
     (WHAT ELSE DO YOU REMEMBER)
     (WHY DO YOU REMEMBER 4 JUST NOW)
     (WHAT IN THE PRESENT SITUATION REMINDS YOU OF 4)
     (WHAT IS THE CONNECTION BETWEEN ME AND 4)
    )
    ((0 DO YOU REMEMBER 0)
     (DID YOU THINK I WOULD FORGET 5)
     (WHY DO YOU THINK I SHOULD RECALL 5 NOW)
     (WHAT ABOUT 5)
     (YOU MENTIONED 5)
   ))
   (DREAMT
    ((0 I DREAMT 0)
     (REALLY 4)
     (HAVE YOU EVER FANTASIED 4 WHILE YOU WERE AWAKE)
     (HAVE YOU DREAMT 4 BEFORE)
   ))
   (DREAM
    ((0)
     (WHAT DOES THAT DREAM SUGGEST TO YOU)
     (DO YOU DREAM OFTEN)
     (WHAT PERSONS APPEAR IN YOUR DREAMS)
     (DON T YOU BELIEVE THAT DREAM HAS SOMETHING TO DO WITH YOUR PROBLEM)
   ))
   (IF
    ((0 IF 0)
     (DO YOU THINK ITS LIKELY THAT 3)
     (DO YOU WISH THAT 3)
     (WHAT DO YOU THINK ABOUT 3)
     (REALLY 2 3)
   ))
   (WHAT
    ((0)
     (WHY DO YOU ASK)
     (DOES THAT QUESTION INTEREST YOU)
     (WHAT IS IT YOU REALLY WANT TO KNOW)
     (ARE SUCH QUESTIONS MUCH ON YOUR MIND)
     (WHAT ANSWER WOULD PLEASE YOU MOST)
     (WHAT DO YOU THINK)
     (WHAT COMES TO YOUR MIND WHEN YOU ASK THAT)
     (HAVE YOU ASKED SUCH QUESTIONS BEFORE)
     (HAVE YOU ASKED ANYONE ELSE)
   ))
   (WHY
    ((0 WHY DON T YOU 0)
     (DO YOU BELIEVE I DON T 6)
     (PERHAPS I WILL 6 IN GOOD TIME)
     (SHOULD YOU 6 YOURSELF)
     (YOU WANT ME TO 6)
    )
    ((0 WHY CAN T I 0)
     (DO YOU THINK YOU SHOULD BE ABLE TO 6)
     (DO YOU WANT TO BE ABLE TO 6)
     (DO YOU BELIEVE THIS WILL HELP YOU TO 6)
     (HAVE YOU ANY IDEA WHY YOU CAN T 6)
   ))
   (SORRY
    ((0)
     (PLEASE DON T APOLOGIZE)
     (APOLOGIES ARE NOT NECESSARY)
     (WHAT FEELINGS DO YOU HAVE WHEN YOU APOLOGIZE)
     (I VE TOLD YOU THAT APOLOGIES ARE NOT REQIRED)
   ))
   (BECAUSE
    ((0)
     (IS THAT THE REAL REASON)
     (DON T ANY OTHER REASONS COME TO MIND)
     (DOES THAT REASON SEEM TO EXPLAIN ANYTHING ELSE)
     (WHAT OTHER REASONS MIGHT THERE BE)
   ))
   (PERHAPS
    ((0)
     (YOU DON T SEEM QUITE CERTAIN)
     (WHY THE UNCERTAIN TONE)
     (CAN T YOU BE MORE POSITIVE)
     (YOU AREN T SURE)
     (DON T YOU KNOW)
   ))
   (YES
    ((0)
     (YOU SEEM QUITE POSITIVE)
     (YOU ARE SURE)
     (I SEE)
     (I UNDERSTAND)
   ))
   (NO
    ((0)
     (ARE YOU SAYING NO JUST TO BE NEGATIVE)
     (YOU ARE BEING A BIT NEGATIVE)
     (WHY NOT)
     (WHY NO)
   ))
   (EVERYONE
    ((0 EVERYONE 0)
     (REALLY 2)
     (SURELY NOT 2)
     (CAN YOU THINK OF ANYONE IN PARTICULAR)
     (WHO FOR EXAMPLE)
     (YOU ARE THINKING OF A VERY SPECIAL PERSON)
     (WHO MAY I ASK)
     (SOMEONE SPECIAL PERHAPS)
     (YOU HAVE A PARTICULAR PERSON IN MIND DON T YOU)
     (WHO DO YOU THINK YOU RE TALKINK ABOUT)
   ))
   (ALWAYS
    ((0)
     (CAN YOU THINK OF A SPECIFIC EXAMPLE)
     (WHEN)
     (WHAT INCIDENT ARE YOU THINKING OF)
     (REALLY ALWAYS)
   ))
   (CAN
    ((0 CAN YOU 0)
     (YOU BELIEVE I CAN 4 DON T YOU)
     (YOU WANT ME TO BE ABLE TO 4)
     (PERHAPS YOU WOULD LIKE TO BE ABLE TO 4 YOURSELF)
    )
    ((0 CAN I 0)
     (WHETHER OR NOT YOU CAN 4 DEPENDS ON YOU MORE THAN ON ME)
     (DO YOU WANT TO BE ABLE TO 4)
     (PERHAPS YOU DON T WANT TO 4)
   ))
   (MY
    ((0 MY 0 (MOTHER FATHER SISTER BROTHER WIFE CHILDREN) 0)
     (TELL ME MORE ABOUT YOUR FAMILY)
     (WHO ELSE IN YOUR FAMILY 5)
     (YOUR 4)
     (WHAT ELSE COMES TO MIND WHEN YOU THINK OF YOUR 4)
    )
    ((0 MY 0)
     (YOUR 3)
     (WHY DO YOU SAY YOUR 3)
     (DOES THAT SUGGEST ANYTHING ELSE WHICH BELONGS TO YOU)
     (IS IT IMPORTANT TO YOU THAT YOUR 3)
   ))
   (YOUR
    ((0 YOUR 0)
     (WHY ARE YOU CONCERNED OVER MY 3)
     (WHAT ABOUT YOUR OWN 3)
     (ARE YOU WORRIED ABOUT SOMEONE ELSES 3)
     (REALLY MY 3)
   ))
   (I
    ((0 I (WANT NEED) 0)
     (WHAT WOULD IT MEAN TO YOU IF YOU GOT 4)
     (WHY DO YOU WANT 4)
     (SUPPOSE YOU GOT 4 SOON)
     (WHAT IF YOU NEVER GOT 4)
     (WHAT WOULD GETTING 4 MEAN TO YOU)
     (WHAT DOES WANTING 4 HAVE TO DO WITH THIS DISCUSSION)
    )
    ((0 I AM 0 (SAD UNHAPPY DEPRESSED SICK) 0)
     (I AM SORRY TO HEAR YOU ARE 5)
     (DO YOU THINK COMING HERE WILL HELP YOU NOT TO BE 5)
     (I M SURE ITS NOT PLEASANT TO BE 5)
     (CAN YOU EXPLAIN WHAT MADE YOU 5)
    )
    ((0 I AM 0 (HAPPY ELATED GLAD BETTER) 0)
     (HOW HAVE I HELPED YOU TO BE 5)
     (HAS YOUR TREATMENT MADE YOU 5)
     (WHAT MAKES YOU 5 JUST NOW)
     (CAN YOU EXPLAIN WHY YOU ARE SUDDENLY 5)
    )
    ((0 I (FEEL THINK BELIEVE WISH) I 0)
     (DO YOU REALLY THINK SO)
     (BUT YOU ARE NOT SURE YOU 5)
     (DO YOU REALLY DOUBT YOU 5)
    )
    ((0 I AM 0)
     (IS IT BECAUSE YOU ARE 4 THAT YOU CAME TO ME)
     (HOW LONG HAVE YOU BEEN 4)
     (DO YOU BELIVE IT NORMAL TO BE 4)
     (DO YOU ENJOY BEING 4)
    )
    ((0 I CAN T 0)
     (HOW DO YOU KNOW YOU CAN T 5)
     (HAVE YOU TRIED)
     (PERHAPS YOU COULD 5 NOW)
     (DO YOU REALLY WANT TO BE ABLE TO 5)
    )
    ((0 I DON T 0)
     (DON T YOU REALLY 5)
     (WHY DON T YOU 5)
     (DO YOU WISH TO BE ABLE TO 5)
     (DOES THAT TROUBLE YOU)
    )
    ((0 I FEEL 0)
     (TELL ME MORE ABOUT SUCH FEELINGS)
     (DO YOU OFTEN FEEL 4)
     (DO YOU ENJOY FEELING 4)
     (OF WHAT DOES FEELING 4 REMIND YOU)
    )
    ((0 I 0 YOU 0)
     (PERHAPS IN YOUR FANTASY WE 3 EACH OTHER)
     (DO YOU WISH TO 3 ME)
     (YOU SEEM TO NEED TO 3 ME)
     (DO YOU 3 ANYONE ELSE)
   ))
   (YOU
    ((0 YOU ARE 0)
     (WHAT MAKES YOU THINK I AM 4)
     (DOES IT PLEASE YOU TO BELIEVE I AM 4)
     (DO YOU SOMETIMES WISH YOU WERE 4)
     (PERHAPS YOU WOULD LIKE TO BE 4)
    )
    ((0 YOU 0 ME)
     (WHY DO YOU THINK I 3 YOU)
     (YOU LIKE TO THINK I 3 YOU DON T YOU)
     (WHAT MAKES YOU THINK I 3 YOU)
     (REALLY I 3 YOU)
     (DO YOU WISH TO BELIEVE I 3 YOU)
     (SUPPOSE I DID 3 YOU WHAT WOULD THAT MEAN)
     (DOES SOMEONE ELSE BELIEVE I 3 YOU)
   ))
   (WAS
    ((0 WAS I 0)
     (WHAT IF YOU WERE 4)
     (WERE YOU 4)
     (WHAT WOULD IT MEAN IF YOU WERE 4)
     (WHAT DOES 4 SUGGEST TO YOU)
    )
    ((0 I WAS 0)
     (WERE YOU REALLY)
     (WHY DO YOU TELL ME YOU WERE 4 NOW)
     (PERHAPS I ALREADY KNEW YOU WERE 4)
   ))
   (WERE
    ((0 WERE YOU 0)
     (WOULD YOU LIKE TO BELIEVE I WAS 4)
     (WHAT SUGGESTS THAT I WAS 4)
     (WHAT DO YOU THINK)
     (PERHAPS I WAS 4)
     (WHAT IF I HAD BEEN 4)
   ))
   (AM
    ((0 AM I 0)
     (DO YOU BELIEVE YOU ARE 4)
     (WOULD YOU WANT TO BE 4)
     (YOU WISH I WOULD TELL YOU YOU ARE 4)
     (WHAT WOULD IT MEAN IF YOU WERE 4)
    )
    ((0)
     (WHY DO YOU SAY AM)
     (I DON T UNDERSTAND THAT)
   ))
   (ARE
    ((0 ARE YOU 0)
     (WHY ARE YOU INTERESTED IN WHETHER I AM 4 OR NOT)
     (WOULD YOU PREFER IF I WEREN T 4)
     (PERHAPS I AM 4 IN YOUR FANTASIES)
     (DO YOU SOMETIMES THINK I AM 4)
    )
    ((0 ARE 0)
     (DID YOU THINK THEY MIGHT NOT BE 3)
     (WOULD YOU LIKE IT IF THEY WERE NOT 3)
     (WHAT IF THEY WERE NOT 3)
     (POSSIBLY THEY ARE 3)
   ))
   (NONE
    ((0)
     (I AM NOT SURE I UNDERSTAND YOU FULLY)
     (PLEASE GO ON)
     (WHAT DOES THAT SUGGEST TO YOU)
     (DO YOU FEEL STRONGLY ABOUT DISCUSSING SUCH THINGS)
   ))
  )
+
      )

  (HELLO)
  (NO)
  (NO)
  (PERHAPS)
  (NO)
  (I DON T KNOW)
  (NO)
  (I DON T KNOW)
  (I DON T KNOW)
  (NO)
  (YOU SAID THAT BEFORE)
  (I SAID YOU SAID THAT BEFORE)
  BYE

EXIT ()

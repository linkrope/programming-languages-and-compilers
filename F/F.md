# Die Programmiersprache F

## 0. Einleitung

F ist eine sehr einfache (erweiterbare) applikative Programmiersprache.
Sie wurde zum Studium der typischen Aspekte der Übersetzung realer Programmiersprachen entworfen.
Die starken Einschränkungen, insbesondere des Typkonzepts, sind Folgen der didaktischen Reduktion.

In den folgenden Abschnitten wird die Syntax der Sprache in EBNF angegeben,
und die Semantik sowie die Kontextbedingungen werden informell beschrieben.

## 1. Symbole und Kommentare

Auf der lexikalischen Ebene besteht ein Programm aus Symbolen (Token),
Kommentaren sowie Zwischenräumen (Leerzeichen, Zeilenenden, Tabulatoren, ...).
Innerhalb von Symbolen dürfen keine Zwischenräume vorkommen.
Zwischenräume werden nicht beachtet, es sei denn zum Trennen aufeinanderfolgender Symbole.
Kommentare werden durch das Zeichen `!` eingeleitet und erstrecken sich bis zum Zeilenende.
Sie beeinflussen die Bedeutung des Programms nicht.

```
number = digit {digit}.
ident = letter {letter | digit}.

digit = "0" | ... | "9".
letter = "a" | ... | "z" | "A" | ... | "Z".
```

Die (vorzeichenlosen) ganzen Zahlen der Form number dürfen Werte zwischen 0 und 2<sup>31</sup> - 1 annehmen.

Jedes Zeichen in einem Namen der Form ident ist signifikant,
ebenso die Groß- und Kleinschreibung der Buchstaben.
Kein reserviertes Wort (`AND`, `BOOL`, `ELSE`, `IF`, `IN`,
`INT`, `LET`, `NOT`, `OR`, `THEN`) darf als Name verwendet werden.

## 2. Ausdrücke

Ausdrücke beschreiben Regeln zur Berechnung von Werten.

Syntaktisch werden nach ihrem Vorrang vier Klassen von Operationen unterschieden.
Die Negation sowie die Vorzeichen haben Vorrang gegenüber den sogenannten Multiplikationsoperationen,
diese haben Vorrang gegenüber den sogenannten Additionsoperationen,
und diese haben Vorrang gegenüber den Relationen.
Gleichrangige Operationen werden von links nach rechts angewendet.
Mit Klammern lassen sich vorrangige Verbindungen festlegen.

```
Expression = SimpleExpr [Relation SimpleExpr]
           | IfExpr | LetExpr.
SimpleExpr = ["+" | "-"] Term {AddOperator Term}.
Term = Factor {MulOperator Factor}.
Factor = number | ident ActualParams
       | "NOT" Factor | "(" Expression ")".

IfExpr = "IF" Expression "THEN" Expression "ELSE" Expression.
LetExpr = "LET" Declarations "IN" Expression.

Relation = "=" | "<>" | "<" | "<=" | ">" | ">=".
AddOperator = "+" | "-" | "OR".
MulOperator = "*" | "/" | "AND".
```

Die Auswertung eines Ausdrucks der Form `number` ergibt den Wert der ganzen Zahl. Der Typ des Ausdrucks ist `INT`.

Die Auswertung eines Ausdrucks der Form `ident`, wobei der Name einen Parameter bezeichnet,
ergibt den an den Namen gebundenen Wert. Der Typ des Ausdrucks ist der Typ des Parameters.

Zur Auswertung eines Ausdrucks der Form `ident ActualParams`,
wobei der Name eine Funktion bezeichnet, werden die aktuellen Parameter ausgewertet,
und die an den Namen gebundene Funktion wird mit diesen Argumenten aufgerufen.
Dabei muß `ActualParams` kompatibel zur Signatur der Funktion sein.
Der Typ des Ausdrucks ist der Ergebnistyp der Funktion.

Zur Auswertung eines Ausdrucks der Form `( Expression )` wird `Expression` ausgewertet.

Zur Auswertung eines bedingten Ausdrucks der Form
<code>IF Expression<sub>1</sub> THEN Expression<sub>2</sub> ELSE Expression<sub>3</sub></code>
wird zunächst<code>Expression<sub>1</sub></code> ausgewertet.
Der Typ von <code>Expression<sub>1</sub></code> muß `BOOL` sein.
Wenn der Wert `TRUE` ist, wird <code>Expression<sub>2</sub></code> ausgewertet;
ist der Wert `FALSE`, <code>Expression<sub>3</sub></code> ausgewertet.
Der Typ des Ausdrucks ist gleich dem Typ von <code>Expression<sub>2</sub></code>
und <code>Expression<sub>3</sub></code>, die übereinstimmen müssen.

Zur Auswertung eines Block-Ausdrucks der Form `LET Declarations IN Expression` wird `Expression` ausgewertet,
in der Umgebung des Block-Ausdrucks, überlagert durch die von `Declarations` erzeugten Bindungen.
Diese Bindungen haben außerhalb des Block-Ausdrucks keine Wirkung.

Zur Auswertung von Ausdrücken der Form `Op Operand` und <code>Operand<sub>1</sub> Op Operand<sub>2</sub></code>
wird die durch `Op` bezeichnete Operation auf die Werte der Operanden angewendet.
In den folgenden Tabellen sind die durch die Operationssymbole bezeichneten Operationen aufgeführt.
Falls ein Operationssymbol unterschiedliche Operationen bezeichnet,
ergibt sich die tatsächliche Operation aus den Typen der Operanden.

## 2.1 Arithmetische Operationen

| Symbol | Operation              |
| ------ | ---------------------- |
| `+`    | Addition               |
| `-`    | Subtraktion            |
| `*`    | Multiplikation         |
| `/`    | (ganzzahlige) Division |

Diese Operationen sind nur auf Operanden des Typs `INT` anwendbar, und das Ergebnis ist ebenfalls vom Typ `INT`.
Werden die Symbole `+` und `-` mit nur einem Operanden als Vorzeichen verwendet,
bezeichnen sie die Identität bzw. die Vorzeichenumkehr.

## 2.2 Logische Operationen

| Symbol | Operation   |
| ------ | ----------- |
| `OR`   | Disjunktion |
| `AND`  | Konjunktion |
| `NOT`  | Negation    |

Diese Operationen sind nur auf Operanden des Typs `BOOL` anwendbar, und das Ergebnis ist ebenfalls vom Typ `BOOL`.

## 2.3 Relationen

| Symbol | Relation            |
| ------ | ------------------- |
| `=`    | gleich              |
| `<>`   | ungleich            |
| `<`    | kleiner             |
| `<=`   | kleiner oder gleich |
| `>`    | größer              |
| `>=`   | größer oder gleich  |

Die Relationen sind auf Operanden des Typs `INT` anwendbar, und das Ergebnis ist vom Typ `BOOL`.
Weiterhin sind `=` und `<>` auch anwendbar, wenn die Operanden vom Typ `BOOL` sind.

## 3. Deklarationen

Deklarationen beschreiben Regeln zur Erzeugung von Bindungen.

Jeder in einem Programm vorkommende Name muß textuell vor seiner Verwendung
entweder als Parameter oder als Funktion deklariert worden sein,
es sei denn, es handelt sich um einen Standardnamen.
Um nun indirekt rekursive Funktionen einfach formulieren zu können,
ist die Deklaration einer Funktion aufgeteilt in einerseits die Angabe ihrer Signatur
und andererseits ihre eigentliche Definition. Bereits durch die Angabe ihrer Signatur,
d.h. durch die Festlegung der Typen der Parameter und des Ergebnistyps, gilt eine Funktion als deklariert.

```
Declarations = (Signature | Definition)
               {Signature | Definition}.

Signature = ident ":" TypeTuple "->" SimpleType.
Definition = ident FormalParams "=" Expression.
```

Durch eine Signatur der Form `ident : TypeTuple -> SimpleType`
wird der Name als Funktion mit dem Ergebnistyp `SimpleType` deklariert.

Durch eine Definition der Form `ident FormalParams = Expression`
wird an den Namen eine Funktion mit Parametern gemäß `FormalParams` und `Expression` als Rumpf gebunden.
Beim Aufruf der Funktion werden die Argumente an die korrespondierenden formalen Parameter gebunden,
und dann wird `Expression` ausgewertet, in der Umgebung der Definition, überlagert durch die Bindungen der Parameter.
Der Typ von `Expression` muß der Ergebnistyp der Funktion sein.

Durch Deklarationen der Form `Declarations` werden die Bindungen aller (direkt) enthaltenen Definitionen erzeugt.
Dabei muß `Declarations` für jede deklarierte Funktion genau eine Angabe der Signatur
und genau eine Definition (direkt) enthalten, und die Signatur muß vor der Definition angegeben sein.
Die Umgebung einer (direkt) enthaltenen Definition ist dann die Umgebung von `Declarations`,
überlagert durch die Bindungen der textuell vorher deklarierten Funktionen.

## 4. Typen und Parameter

Ein Typ legt den Wertebereich für Parameter und Ausdrücke dieses Typs fest.

Formale Parameter einer Funktion sind die Namen,
an die beim Aufruf der Funktion die korrespondierenden Argumente gebunden werden.
Diese Argumente ergeben sich durch die Auswertung der aktuellen Parameter.
Die Typen der formalen Parameter sind durch die zugehörige Signatur festgelegt.

```
SimpleType = "BOOL" | "INT".
TypeTuple = [SimpleType {"*" SimpleType}].

FormalParams = ["(" ident {"," ident} ")"].
ActualParams = ["(" Expression {"," Expression} ")"].
```

Der Typ `BOOL` bezeichnet die Wahrheitswerte, der Typ `INT` die ganzen Zahlen.

Aktuelle Parameter der Form <code>Expression<sub>1</sub>, ..., Expression<sub>n</sub></code> (n ≥ 0)
sind kompatibel zur Signatur der Form
<code>ident : SimpleType<sub>1</sub> * ... * SimpleType<sub>m</sub> -> SimpleType</code> (m ≥ 0),
wenn m = n gilt und jeder Ausdruck <code>Expression<sub>k</sub></code>
vom Typ <code>SimpleType<sub>k</sub></code>> ist (1 ≤ k ≤ m).
Für formale Parameter der Form <code>ident<sub>1</sub>, ..., ident<sub>m</sub></code>
ist dann <code>ident<sub>k</sub></code> vom Typ <code>SimpleType<sub>k</sub></code> (1 ≤ k ≤ m).
Die Namen der formalen Parameter müssen verschieden sein.

## 5. Programme

Programme bestehen aus einer einzigen Funktionsdeklaration (siehe 3. Deklarationen).

```
CompilationUnit = Signature Definition.
```

Die Umgebung eines Programms enthält die Bindungen der einzigen Standardnamen
`TRUE` und `FALSE` an die entsprechenden Wahrheitswerte.

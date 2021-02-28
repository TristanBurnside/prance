# Loops and Branches

Loops and branches allow for more complicated logic than simple statements and
variables. Loops allow the same code to be run repeatedly and branches allow for
code to be run only when some condition is met.

## If-else

To run code only in when certain criteria are met, you should use the if syntax.

```
var x: Int
x = 1
if (x > 0) {
  print(line: "X is positive")
}
```

to run code when the criteria are not met, add an else block.

```
var x: Int
x = 1
if (x > 0) {
  print(line: "X is positive")
} else {
  print(line: "X is not positive")
}

```

## For

Prance includes c-style for loops. In these you specify a declaration, a condition,
a post loop action and a body

```
var i: Int

for (i = 5; i > 0; i = i - 1) {
  print(line: "Repeat")
}
```

## While

A simpler loop than for is the while loop, in this loop style you only need to
provide the condition to be run at the start of each loop.

```
var i: Int
i = 5
while(i > 0) {
  print(line: "Repeat")
  i = i - 1
}
```

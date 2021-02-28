# Functions

Functions represent reusable blocks of code that can be invoked.

```
fun speak() {
  print(line: "Hello")
}
```

The above defines a function called 'speak', it has no direct input or output
and prints "Hello" to stdout.

To call this function you give the name followed by "()"

Code:
`speak()`
Output:
`Hello`

## Arguments

Inputs to functions are defined in the declaration. Every argument must have a name
and a type.

```
fun speak(word: String) {
  print(line: word)
}
```

When calling a function, you must include all of the argument labels

Code:
`speak(word: "Goodbye")`
Output:
`Goodbye`

## Return Types

A function can also return a value.

```
fun speak(hourOfDay: Int) String {
  if (hourOfDay < 12) {
    return "Good Morning!"
  } else {
    return "Good Night!"
  }
}
```

Function return values can be stored into a variable, or passed to another function.

Code:
`print(line: speak(hourOfDay: 5))`
`print(line: speak(hourOfDay: 15))`
Output:
`Good Morning!`
`Good Night!`

# Custom Types

In Prance you can define your own types in addition to the basic types.
Instances of these types will created on the heap and they are always passed
by reference to functions.

Types are defined with the "type" keyword.

`type Dog {}`

By convention, all types start with a upper-case letter and use camel-case.

## Properties

A type may declare internal properties.

```
type Dog {
  var name: String
  var age: Int
}
```

To create an instance of a type, call the built in initialization function. This is
defined as the type name followed by all the properties as arguments.

`var harry: Dog`
`Dog(name: "Harry", age: 3)`

Properties of an instance can be referred to using the '.' syntax.

Code:
`print(line: harry.name)`
Output:
`Harry`

## Methods

A type may also declare functions that operate on instances of that type.

```
type Dog {
  ...
  fun speak() {
    print(line: "Woof!")
  }
}
```

Methods are also called using the '.' syntax.

Code:
`harry.speak()`
Output:
`Woof!`

Just like functions, methods can have arguments and return types. Additionally,
a method may access properties on the instance that was used to call the method.
Properties are accessed using the implicit 'self' argument of a method.

```
type Dog {
  var name: String
  var age: Int

  fun ageAfter(years: Int) Int {
    return years + self.age
  }
}
```

## Protocol conformance

Types may also conform to protocols, see the protocol section for more details

```
protocol Speaker {
  fun speak()
}

type Dog: Speaker {
  fun speak() {}
}
```

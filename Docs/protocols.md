# Protocols

Protocols define a set of functionality that is common to a series of types.

```
protocol Speaker {
  fun speak() String
}
```

Types conform to protocols in their definition and must implement all of the
methods declared in the protocol but they are free to implement the body
of each method in any way.

```
type Dog: Speaker {
  fun speak() String {
    return "Woof!"
  }
}

type Person: Speaker {
  fun speak() String {
    return "Hello"
  }
}
```

Protocols can be used in many of the same places that types are used. Variables
can be declared using a protocol as the type. If a variable is of a protocol type
it may be assigned an instance of any type that conforms to the protocol.

Code:
```
var speaker: Speaker
speaker = Dog()
print(line: speaker.speak())
speaker = Person()
print(line: speaker.speak())
```
Output:
```
Woof!
Hello
```

When using a variable of a protocol type you can only access methods that belong
to that protocol, you cannot access methods or properties of the type of the
current instance.

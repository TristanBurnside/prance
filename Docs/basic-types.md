# Basic types

Prance provides 4 basic types: Double, Int, Float and String.

## Double

A double-width floating point type. Double values must be declared with a '.'
and at least one digit before and after the '.'.

`40.5`
`0.01`
`5932.294804`

Leading and trailing zeros are accepted but discouraged, except where necessary to
make sure there is at least one digit.

## Float

The single width floating point type. It is defined the same as double but with
an 'f' on the end of the value.

`50.8f`
`4.0f`
`0.32f`

## Int

An integer type. Values are defined as whole numbers without a '.'.

`4`
`454566`
`0`

## String

A series of characters. All strings are immutable once created. A string value is
defined by sourrounding the characters in '""'.

`"Hello"`
`"Tristan"`

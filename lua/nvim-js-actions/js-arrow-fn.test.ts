const foo = bar => "baz"
const foo1 = (bar) => "baz"
const foo2 = <T>(bar: number) => "baz"
const foo3 = (bar, fizz: string, buzz) => {
  return "baz"
}
console.log((bar => "baz")())
console.log(((bar) => "baz")())
console.log((<T>(bar: number) => "baz")(5))

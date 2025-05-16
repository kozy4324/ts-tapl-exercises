import { assert, assertEquals, assertThrows } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseBasic } from "npm:tiny-ts-parser";
import { typecheck, Type, typeEq } from "./basic.ts";

const source = (strings: TemplateStringsArray) => strings.join('').replaceAll(/\s*\n\s*/g, ' ').trim();

const expectResult = (expected: Type) => {
  return (context: Deno.TestContext) => {
    const result = typecheck(parseBasic(context.name), {});
    assertEquals(result, expected);
  }
}

const expectThrow = (expected: string) => {
  return (context: Deno.TestContext) => {
    assertThrows(() => {
      typecheck(parseBasic(context.name), {});
    }, Error, expected);
  }
}

Deno.test("1 + 2", expectResult({ tag: "Number" }));
Deno.test("1 + true", expectThrow("number expected"));
Deno.test("1 + (2 + 3)", expectResult({ tag: "Number" }));
Deno.test("true ? 1 : 2", expectResult({ tag: "Number" }));
Deno.test("true ? false : true", expectResult({ tag: "Boolean" }));
Deno.test("1 ? 2 : 3", expectThrow("boolean expected"));
Deno.test("true ? 1 : true", expectThrow("then and else have different types"));
Deno.test("true ? (1 + 2) : (3 + (false ? 4 : 5))", expectResult({ tag: "Number" }));

Deno.test("(x: boolean) => 42;", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Boolean" } }], retType: { tag: "Number" } }));
Deno.test("(x: number) => x;", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } }));
Deno.test("(x: number, y: number) => x + y;", expectResult({ tag: "Func", params: [{ name: "x", type: { tag: "Number" } }, { name: "y", type: { tag: "Number" } }], retType: { tag: "Number" } }));
Deno.test("(x: number, y: number) => x + z;", expectThrow("variable not found"));
Deno.test("( (x: number) => x )(42);", expectResult({ tag: "Number" }));
Deno.test("( (x: number) => x )(true);", expectThrow("argument type mismatch"));
Deno.test("( (x: number) => 42 )(1, 2, 3);", expectThrow("wrong number of arguments"));
Deno.test("(f: (x: number) => number) => 1", expectResult({ tag: "Func", params: [{ name: "f", type: { tag: "Func", params: [{ name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } } }], retType: { tag: "Number" } }));
/*
Deno.test(source`
  const add = (x: number, y: number) => x + y;
  const select = (b: boolean, x: number, y: number) => b ? x : y;
  const x = add(1, add(2, 3));
  select(true, x, x);
`, expectResult({ tag: "Func", params: [], retType: { tag: "Number" } }));
*/

Deno.test("Boolean vs Boolean", () => assert(typeEq({ tag: "Boolean" }, { tag: "Boolean" })));
Deno.test("Number vs Number", () => assert(typeEq({ tag: "Number" }, { tag: "Number" })));
Deno.test("Boolean vs Number", () => assert(!typeEq({ tag: "Boolean" }, { tag: "Number" })));
Deno.test("Number vs Boolean", () => assert(!typeEq({ tag: "Number" }, { tag: "Boolean" })));
Deno.test("Func vs Func", () => assert(typeEq({ tag: "Func", params: [], retType: { tag: "Number" } }, { tag: "Func", params: [], retType: { tag: "Number" } })));
Deno.test("Func vs Boolean", () => assert(!typeEq({ tag: "Func", params: [], retType: { tag: "Number" } }, { tag: "Boolean" })));
Deno.test("Func: params.length not match", () => assert(!typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [                                       ], retType: { tag: "Number" } }
)));
Deno.test("Func: params.length match", () => assert(typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } }
)));
Deno.test("Func: params type not match", () => assert(!typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number"  } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "x", type: { tag: "Boolean" } }], retType: { tag: "Number" } }
)));
Deno.test("Func: retType not match", () => assert(!typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Boolean" } }
)));
Deno.test("Func: param name mismatch is not cared", () => assert(typeEq(
  { tag: "Func", params: [ { name: "x", type: { tag: "Number" } }], retType: { tag: "Number" } },
  { tag: "Func", params: [ { name: "y", type: { tag: "Number" } }], retType: { tag: "Number" } }
)));

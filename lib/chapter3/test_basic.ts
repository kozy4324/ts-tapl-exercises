import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseBasic } from "npm:tiny-ts-parser";
import { typecheck, Type } from "./basic.ts";

const expectResult = (expected: Type) => {
  return (context: Deno.TestContext) => {
    const result = typecheck(parseBasic(context.name));
    assertEquals(result, expected);
  }
}

const expectThrow = (expected: string) => {
  return (context: Deno.TestContext) => {
    try {
      typecheck(parseBasic(context.name));
    } catch (e) {
      assertEquals(e, expected);
      return;
    }
    assert(false, `Expected error: ${expected}`);
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

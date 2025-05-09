import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseArith } from "npm:tiny-ts-parser";

Deno.test("parseArith", () => assertEquals(parseArith("100").tag, "number"));

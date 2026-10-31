import { describe, expect, test } from "bun:test";
import { getObjectValueByPath, setObjectValueByPath } from "../lua/kulala/parser/scripts/engines/javascript/lib/src/lib/Utils";

describe("request variable paths", () => {
  test("sets and reads nested variables", () => {
    const variables = setObjectValueByPath({}, "session.id", "test-id");
    expect(getObjectValueByPath(variables, "session.id")).toBe("test-id");
  });

  test.each(["__proto__.polluted", "constructor.prototype.polluted", "nested.__proto__.polluted"])(
    "rejects prototype traversal: %s",
    (path) => {
      expect(() => setObjectValueByPath({}, path, "bad")).toThrow("Unsafe variable path");
      expect(getObjectValueByPath({}, path)).toBeUndefined();
      expect(({} as Record<string, unknown>).polluted).toBeUndefined();
    },
  );

  test("does not read inherited properties", () => {
    expect(getObjectValueByPath(Object.create({ inherited: "not-a-variable" }), "inherited")).toBeUndefined();
  });
});

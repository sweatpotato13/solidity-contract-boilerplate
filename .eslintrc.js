require("@rushstack/eslint-patch/modern-module-resolution");

module.exports = {
    root: true,
    plugins: ["prettier"],
    extends: ["@chainsafe", "prettier"],
    rules: {
        "prettier/prettier": "error",
        "@typescript-eslint/no-unsafe-member-access": 0,
        "@typescript-eslint/no-unsafe-call": 0,
        "@typescript-eslint/no-unsafe-assignment": 0,
        "@typescript-eslint/no-unsafe-argument": 0,
        "@typescript-eslint/unbound-method": 0,
    },
};

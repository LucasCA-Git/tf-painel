// Conventional Commits com escopos do projeto (ADR-0005).
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "scope-enum": [
      2,
      "always",
      ["bootstrap", "network", "compute", "envs", "ci", "bmad", "adr", "deps", "release", "repo"],
    ],
    "subject-case": [2, "never", ["start-case", "pascal-case", "upper-case"]],
    "body-max-line-length": [1, "always", 100],
  },
};

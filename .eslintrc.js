module.exports = {
  root: true,
  extends: ["eslint:recommended"],
  rules: {
    "no-warning-comments": ["error", { "terms": ["TODO", "FIXME", "JIRA", "TASK"], "location": "anywhere" }],
    "no-console": "off"
  }
};

#!/usr/bin/env node

import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../site/dist/app.js", import.meta.url), "utf8");
const catalogSource = source.split("let currentModule=")[0] + "\nglobalThis.__tools = tools;";
const context = {};
vm.createContext(context);
vm.runInContext(catalogSource, context, { filename: "site/dist/app.js" });
const tools = context.__tools;

const expectedCounts = { doctor: 1, dns: 20, dhcp: 14, samba: 18, web: 14, ftp: 25, mail: 15, storage: 16 };
const allowed = {
  doctor: { run: null },
  dns: {
    install: null, network: ["static", "dhcp", "list"], zone: ["add", "add-reverse", "add-secondary", "list", "remove"],
    record: ["add", "list", "remove"], transfer: ["allow"], forwarders: ["set", "clear"], query: null,
    config: ["show", "check", "rollback"], service: null,
  },
  dhcp: {
    install: null, scope: ["add", "update", "list", "remove"], reservation: ["add", "list", "remove"],
    lease: ["list", "release"], config: ["show", "check", "rollback"], service: null,
  },
  samba: {
    install: null, share: ["add-public", "add-group", "list", "remove"], user: ["add", "remove", "list"],
    permissions: ["grant"], status: null, sessions: null, config: ["show", "check", "apply", "rollback"],
    service: null, client: ["list", "copy"],
  },
  web: {
    install: null, site: ["add", "list", "show", "remove", "backup", "restore"], dns: ["setup", "remove"],
    log: null, config: ["show", "check", "rollback"], service: null,
  },
  ftp: {
    install: null, dns: ["setup", "check", "remove"], share: ["add-anonymous", "list", "remove", "backup", "restore"],
    user: ["add", "list", "remove", "lock", "unlock"], status: null, sessions: null, diagnose: null, log: null,
    tls: ["configure", "disable", "status"], config: ["show", "check", "rollback"], service: null,
  },
  mail: {
    install: null, configure: null, dns: ["setup", "check"], user: ["add", "list", "remove"], status: null,
    queue: null, log: null, test: null, config: ["show", "check", "rollback"], service: null,
  },
  storage: {
    disk: ["list", "free"], partition: ["create"], filesystem: ["format", "mount", "list"],
    lvm: ["install", "list", "pv-create", "vg-create", "vg-extend", "lv-create", "lv-extend"],
    quota: ["enable", "set", "report"],
  },
};

const errors = [];
const counts = {};
for (const tool of tools) {
  counts[tool.module] = (counts[tool.module] || 0) + 1;
  const tokens = tool.args.trim().split(/\s+/);
  const [module, command, action] = tokens;
  if (module !== tool.module) errors.push(`${tool.name}: module '${module}' khác '${tool.module}'`);
  const commandRule = allowed[module]?.[command];
  if (!(command in (allowed[module] || {}))) errors.push(`${tool.name}: route không tồn tại: ${module} ${command || ""}`);
  else if (Array.isArray(commandRule) && !commandRule.includes(action)) errors.push(`${tool.name}: action không tồn tại: ${module} ${command} ${action || ""}`);

  const placeholders = [...tool.args.matchAll(/\{([^}]+)\}/g)].map((match) => match[1]);
  const fieldKeys = tool.fields.map((field) => field.key);
  for (const key of placeholders) if (!fieldKeys.includes(key)) errors.push(`${tool.name}: thiếu field cho {${key}}`);
  for (const key of fieldKeys) if (!placeholders.includes(key) && key !== "password") errors.push(`${tool.name}: field '${key}' không được dùng trong command`);
  if (new Set(placeholders).size !== placeholders.length) errors.push(`${tool.name}: placeholder bị lặp`);
}

for (const [module, expected] of Object.entries(expectedCounts)) {
  if ((counts[module] || 0) !== expected) errors.push(`${module}: mong đợi ${expected}, thực tế ${counts[module] || 0}`);
}
if (tools.length !== 123) errors.push(`Tổng tool mong đợi 123, thực tế ${tools.length}`);

console.log("MODULE\tTOOLS\tSTATUS");
for (const module of Object.keys(expectedCounts)) console.log(`${module}\t${counts[module] || 0}\t${(counts[module] || 0) === expectedCounts[module] ? "OK" : "FAIL"}`);
console.log(`TOTAL\t${tools.length}\t${errors.length ? "FAIL" : "OK"}`);

if (errors.length) {
  console.error("\nCatalog errors:");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}


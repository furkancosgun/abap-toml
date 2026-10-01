import express from "express";
import fs from "node:fs";
import path from "node:path";

const initPath = path.resolve("output/init.mjs");
if (!fs.existsSync(initPath)) {
    console.error("❌ Error: Transpiled ABAP output not found. Please run 'npm run unit' or 'npm run exec' first.");
    process.exit(1);
}

const { initializeABAP } = await import("../output/init.mjs");
await initializeABAP();

let cl_express_icf_shim;
try {
    const shimModule = await import("../output/cl_express_icf_shim.clas.mjs");
    cl_express_icf_shim = shimModule.cl_express_icf_shim;
} catch {
    console.error("❌ Error: cl_express_icf_shim not found in output/. Ensure express-icf-shim is present in deps/.");
    process.exit(1);
}

const PORT = parseInt(process.env.PORT, 10) || 3000;
const HANDLER_CLASS = process.env.HANDLER_CLASS || "zcl_sicf_node";

const app = express();
app.disable("x-powered-by");
app.set("etag", false);
app.use(express.raw({ type: "*/*", limit: "10mb" }));

app.use(async (req, res) => {
    if (!req.body) {
        req.body = Buffer.alloc(0);
    }
    try {
        await cl_express_icf_shim.run({ req, res, class: HANDLER_CLASS });
    } catch (err) {
        console.error("❌ Error processing ICF request:", err);
        if (!res.headersSent) {
            res.status(500).send("Internal Server Error in ABAP ICF Handler");
        }
    }
});

const server = app.listen(PORT, () => {
    console.log(`🚀 ABAP ICF Express Server running on http://localhost:${PORT}`);
    console.log(`📡 Handler Class: ${HANDLER_CLASS.toUpperCase()} (override with HANDLER_CLASS=zcl_my_handler)`);
});

server.on("error", (err) => {
    console.error("❌ Failed to start server:", err.message);
    process.exit(1);
});

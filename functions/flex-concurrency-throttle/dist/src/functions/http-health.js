"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const functions_1 = require("@azure/functions");
functions_1.app.http("http-health", {
    methods: ["GET"],
    authLevel: "anonymous",
    handler: async (request, context) => {
        return {
            status: 200,
            jsonBody: {
                status: "ok",
                timestamp: new Date().toISOString(),
                instanceId: process.env.WEBSITE_INSTANCE_ID || "local",
            },
        };
    },
});

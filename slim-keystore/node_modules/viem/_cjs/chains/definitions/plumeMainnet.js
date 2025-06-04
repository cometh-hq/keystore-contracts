"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.plumeMainnet = void 0;
const defineChain_js_1 = require("../../utils/chain/defineChain.js");
const sourceId = 1;
exports.plumeMainnet = (0, defineChain_js_1.defineChain)({
    id: 98_866,
    name: 'Plume Mainnet',
    nativeCurrency: {
        name: 'Plume',
        symbol: 'PLUME',
        decimals: 18,
    },
    rpcUrls: {
        default: {
            http: ['https://phoenix-rpc.plumenetwork.xyz'],
            webSocket: ['wss://phoenix-rpc.plumenetwork.xyz'],
        },
    },
    blockExplorers: {
        default: {
            name: 'Blockscout',
            url: 'https://phoenix-explorer.plumenetwork.xyz',
            apiUrl: 'https://phoenix-explorer.plumenetwork.xyz/api',
        },
    },
    sourceId,
});
//# sourceMappingURL=plumeMainnet.js.map
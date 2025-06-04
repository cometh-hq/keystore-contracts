"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sonicBlazeTestnet = void 0;
const defineChain_js_1 = require("../../utils/chain/defineChain.js");
exports.sonicBlazeTestnet = (0, defineChain_js_1.defineChain)({
    id: 57_054,
    name: 'Sonic Blaze Testnet',
    nativeCurrency: {
        decimals: 18,
        name: 'Sonic',
        symbol: 'S',
    },
    rpcUrls: {
        default: { http: ['https://rpc.blaze.soniclabs.com'] },
    },
    blockExplorers: {
        default: {
            name: 'Sonic Blaze Testnet Explorer',
            url: 'https://testnet.sonicscan.org',
        },
    },
    testnet: true,
});
//# sourceMappingURL=sonicBlazeTestnet.js.map
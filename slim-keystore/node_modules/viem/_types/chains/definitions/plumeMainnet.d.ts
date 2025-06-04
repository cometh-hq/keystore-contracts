export declare const plumeMainnet: {
    blockExplorers: {
        readonly default: {
            readonly name: "Blockscout";
            readonly url: "https://phoenix-explorer.plumenetwork.xyz";
            readonly apiUrl: "https://phoenix-explorer.plumenetwork.xyz/api";
        };
    };
    contracts?: import("../index.js").Prettify<{
        [key: string]: import("../../index.js").ChainContract | {
            [sourceId: number]: import("../../index.js").ChainContract | undefined;
        } | undefined;
    } & {
        ensRegistry?: import("../../index.js").ChainContract | undefined;
        ensUniversalResolver?: import("../../index.js").ChainContract | undefined;
        multicall3?: import("../../index.js").ChainContract | undefined;
        universalSignatureVerifier?: import("../../index.js").ChainContract | undefined;
    }> | undefined;
    id: 98866;
    name: "Plume Mainnet";
    nativeCurrency: {
        readonly name: "Plume";
        readonly symbol: "PLUME";
        readonly decimals: 18;
    };
    rpcUrls: {
        readonly default: {
            readonly http: readonly ["https://phoenix-rpc.plumenetwork.xyz"];
            readonly webSocket: readonly ["wss://phoenix-rpc.plumenetwork.xyz"];
        };
    };
    sourceId: 1;
    testnet?: boolean | undefined;
    custom?: Record<string, unknown> | undefined;
    fees?: import("../../index.js").ChainFees<undefined> | undefined;
    formatters?: undefined;
    serializers?: import("../../index.js").ChainSerializers<undefined, import("../../index.js").TransactionSerializable> | undefined;
};
//# sourceMappingURL=plumeMainnet.d.ts.map
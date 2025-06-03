import type { Config } from '../config.js';
import type { MaybeArray } from '../types.js';
type ResolveConfigParameters = {
    /** Path to config file */
    configPath: string;
};
/** Bundles and returns wagmi config object from path. */
export declare function resolveConfig(parameters: ResolveConfigParameters): Promise<MaybeArray<Config>>;
export {};
//# sourceMappingURL=resolveConfig.d.ts.map
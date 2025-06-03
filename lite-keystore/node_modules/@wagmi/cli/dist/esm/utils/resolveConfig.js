import { bundleRequire } from 'bundle-require';
/** Bundles and returns wagmi config object from path. */
export async function resolveConfig(parameters) {
    const { configPath } = parameters;
    const res = await bundleRequire({ filepath: configPath });
    let config = res.mod.default;
    if (config.default)
        config = config.default;
    if (typeof config !== 'function')
        return config;
    return await config();
}
//# sourceMappingURL=resolveConfig.js.map
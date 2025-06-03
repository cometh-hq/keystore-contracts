import { type Config } from '../config.js';
export type Init = {
    /** Path to config file */
    config?: string;
    /** Watch for file system changes to config and plugins */
    content?: Config;
    /** Directory to init config file */
    root?: string;
};
export declare function init(options?: Init): Promise<string>;
//# sourceMappingURL=init.d.ts.map
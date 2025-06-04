import { z } from 'zod';
declare const Generate: z.ZodObject<{
    /** Path to config file */
    config: z.ZodOptional<z.ZodString>;
    /** Directory to search for config file */
    root: z.ZodOptional<z.ZodString>;
    /** Watch for file system changes to config and plugins */
    watch: z.ZodOptional<z.ZodBoolean>;
}, "strip", z.ZodTypeAny, {
    config?: string | undefined;
    root?: string | undefined;
    watch?: boolean | undefined;
}, {
    config?: string | undefined;
    root?: string | undefined;
    watch?: boolean | undefined;
}>;
export type Generate = z.infer<typeof Generate>;
export declare function generate(options?: Generate): Promise<void>;
export {};
//# sourceMappingURL=generate.d.ts.map
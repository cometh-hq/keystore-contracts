import { defineConfig } from "@wagmi/cli"
import { foundry } from '@wagmi/cli/plugins'

export default defineConfig(
    [
        {
            out: "abi/crossChainValidator.ts",
            plugins: [
                foundry({
                    project: './',
                    artifacts: 'out/',
                    include: [
                        'CrossChainValidator.json',
                    ]
                }),
            ],
        },

    ]
)
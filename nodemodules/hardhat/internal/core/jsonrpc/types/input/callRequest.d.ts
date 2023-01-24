import * as t from "io-ts";
export declare const rpcCallRequest: t.TypeC<{
    from: t.Type<Buffer | undefined, Buffer | undefined, unknown>;
    to: t.Type<Buffer | undefined, Buffer | undefined, unknown>;
    gas: t.Type<bigint | undefined, bigint | undefined, unknown>;
    gasPrice: t.Type<bigint | undefined, bigint | undefined, unknown>;
    value: t.Type<bigint | undefined, bigint | undefined, unknown>;
    data: t.Type<Buffer | undefined, Buffer | undefined, unknown>;
    accessList: t.Type<{
        address: Buffer;
        storageKeys: Buffer[] | null;
    }[] | undefined, {
        address: Buffer;
        storageKeys: Buffer[] | null;
    }[] | undefined, unknown>;
    maxFeePerGas: t.Type<bigint | undefined, bigint | undefined, unknown>;
    maxPriorityFeePerGas: t.Type<bigint | undefined, bigint | undefined, unknown>;
}>;
export declare type RpcCallRequest = t.TypeOf<typeof rpcCallRequest>;
//# sourceMappingURL=callRequest.d.ts.map
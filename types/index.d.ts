/*
 * CHMPX
 *
 * Copyright 2015 Yahoo Japan Corporation.
 *
 * CHMPX is inprocess data exchange by MQ with consistent hashing.
 * CHMPX is made for the purpose of the construction of
 * original messaging system and the offer of the client
 * library.
 * CHMPX transfers messages between the client and the server/
 * slave. CHMPX based servers are dispersed by consistent
 * hashing and are automatically laid out. As a result, it
 * provides a high performance, a high scalability.
 *
 * For the full copyright and license information, please view
 * the license file that was distributed with this source code.
 *
 * AUTHOR:   Takeshi Nakatani
 * CREATE:   Wed Jan 7 2026
 * REVISION:
 *
 */

//-------------------------------------------------------------
// This uses 'export' to be compatible with CommonJS consumers:
//	const chmpx = require('chmpx');
//
// And works for ESM consumers with default import:
//	import chmpx from 'chmpx';
//-------------------------------------------------------------

//
// callable / constructible main factory
//
declare function chmpx(): chmpx.ChmpxNode;

declare namespace chmpx
{
	//---------------------------------------------------------
	// Callback types for ChmpxNode
	//---------------------------------------------------------
	// [NOTE]
	// We allow Error in case it might be changed to an Error object
	// in the future, but currently we do not return Error.
	//
	export type ChmpxInitializeOnServerCallback = (err?: Error | string | null) => void;
	export type ChmpxInitializeOnSlaveCallback = (err?: Error | string | null) => void;
	export type ChmpxOpenCallback = (err?: Error | string | null, msgid?: Buffer) => void;
	export type ChmpxCloseCallback = (err?: Error | string | null) => void;
	export type ChmpxSendCallback = (err?: Error | string | null, recievercnt?: number) => void;
	export type ChmpxBroadcastCallback = (err?: Error | string | null, recievercnt?: number) => void;
	export type ChmpxReplyCallback = (err?: Error | string | null) => void;
	export type ChmpxReceiveCallback = (err?: Error | string | null, compkt?: Buffer, body?: Buffer) => void;

	//---------------------------------------------------------
	// Emitter callback types for ChmpxNode
	//---------------------------------------------------------
	export type OnChmpxEmitterCallback = (err?: string | null, ...args: any[]) => void;
	export type OnChmpxInitializeOnServerEmitterCallback = (err?: string | null) => void;
	export type OnChmpxInitializeOnSlaveEmitterCallback = (err?: string | null) => void;
	export type OnChmpxOpenEmitterCallback = (err?: string | null, msgid?: Buffer) => void;
	export type OnChmpxCloseEmitterCallback = (err?: string | null) => void;
	export type OnChmpxSendEmitterCallback = (err?: string | null, recievercnt?: number) => void;
	export type OnChmpxBroadcastEmitterCallback = (err?: string | null, recievercnt?: number) => void;
	export type OnChmpxReplyEmitterCallback = (err?: string | null) => void;
	export type OnChmpxReceiveEmitterCallback = (err?: string | null, compkt?: Buffer, body?: Buffer) => void;

	//---------------------------------------------------------
	// ChmpxNode Class
	//---------------------------------------------------------
	export class ChmpxNode
	{
		// Constructor
		constructor();	// always no arguments

		//-----------------------------------------------------
		// Methods (Callback can be called)
		//-----------------------------------------------------
		// initialize on server
		initializeOnServer(filename: string, cb?: ChmpxInitializeOnServerCallback): boolean;
		initializeOnServer(filename: string, is_auto_rejoin: boolean, cb?: ChmpxInitializeOnServerCallback): boolean;

		// initialize on slave
		initializeOnSlave(filename: string, cb?: ChmpxInitializeOnSlaveCallback): boolean;
		initializeOnSlave(filename: string, is_auto_rejoin: boolean, cb?: ChmpxInitializeOnSlaveCallback): boolean;

		// send
		send(msgid: Buffer, body: Buffer, cb: ChmpxSendCallback): boolean;
		send(msgid: Buffer, body: Buffer, is_routing: boolean, cb: ChmpxSendCallback): boolean;

		// broadcast
		broadcast(msgid: Buffer, body: Buffer, cb: ChmpxBroadcastCallback): boolean;

		// reply
		reply(compkt: Buffer, body: Buffer, cb?: ChmpxReplyCallback): boolean;

		// receive on server
		receive(cb?: ChmpxReceiveCallback): boolean;
		receive(timeout_ms: number, cb?: ChmpxReceiveCallback): boolean;
		receive(timeout_ms: number, no_giveup_rejoin: boolean, cb?: ChmpxReceiveCallback): boolean;

		// receive on slave
		receive(msgid: Buffer, cb?: ChmpxReceiveCallback): boolean;
		receive(msgid: Buffer, timeout_ms: number, cb?: ChmpxReceiveCallback): boolean;

		// open
		open(): Buffer;
		open(no_giveup_rejoin: boolean): Buffer;

		open(cb: ChmpxOpenCallback): boolean;
		open(no_giveup_rejoin: boolean, cb: ChmpxOpenCallback): boolean;

		// close
		close(msgid: Buffer, cb?: ChmpxCloseCallback): boolean;

		//-----------------------------------------------------
		// Methods (no callback)
		//-----------------------------------------------------
		// send
		send(msgid: Buffer, body: Buffer): number;
		send(msgid: Buffer, body: Buffer, is_routing: boolean): number;

		// broadcast
		broadcast(msgid: Buffer, body: Buffer): number;

		// reply
		reply(compkt: Buffer, body: Buffer): number;

		// receive on server
		receive(rcvarr: [Buffer?, Buffer?]): boolean;
		receive(rcvarr: [Buffer?, Buffer?], timeout_ms: number, no_giveup_rejoin?: boolean): boolean;

		// receive on slave
		receive(msgid: Buffer, rcvarr: [Buffer?, Buffer?], timeout_ms?: number): boolean;

		// check
		isChmpxExit(): boolean;

		//-----------------------------------------------------
		// Emitter registration/unregistration
		//-----------------------------------------------------
		on(emitter: string, cb: OnChmpxEmitterCallback): boolean;
		onInitializeOnServer(cb: OnChmpxInitializeOnServerEmitterCallback): boolean;
		onInitializeOnSlave(cb: OnChmpxInitializeOnSlaveEmitterCallback): boolean;
		onOpen(cb: OnChmpxOpenEmitterCallback): boolean;
		onClose(cb: OnChmpxCloseEmitterCallback): boolean;
		onSend(cb: OnChmpxSendEmitterCallback): boolean;
		onBroadcast(cb: OnChmpxBroadcastEmitterCallback): boolean;
		onReply(cb: OnChmpxReplyEmitterCallback): boolean;
		onReceive(cb: OnChmpxReceiveEmitterCallback): boolean;

		off(emitter: string): boolean;
		offInitializeOnServer(): boolean;
		offInitializeOnSlave(): boolean;
		offOpen(): boolean;
		offClose(): boolean;
		offSend(): boolean;
		offBroadcast(): boolean;
		offReply(): boolean;
		offReceive(): boolean;

		//-----------------------------------------------------
		// Promise APIs(Currently no imprelemnts)
		//-----------------------------------------------------
		// [NOTE]
		// Although it is not currently implemented, here is an example definition:
		//
		// ex.	receive(rcvarr: [Buffer?, Buffer?], timeout_ms: number, no_giveup_rejoin: boolean): Promise<boolean>;
		//
	}

	//---------------------------------------------------------
	// ChmpxFactoryType
	//---------------------------------------------------------
	export type ChmpxFactoryType = {
		():			ChmpxNode;
		new():		ChmpxNode;
		ChmpxNode:	typeof ChmpxNode;
	};
} // end namespace chmpx

//-------------------------------------------------------------
// Exports
//-------------------------------------------------------------
//
// UMD global name
//
export as namespace chmpx;

//
// CommonJS default export
//
export = chmpx;

//
// Ambient module
//
// For "import", "import type" users(type-only export).
// This provides named type exports(type-only).
//
declare module 'chmpx'
{
	//
	// Default(value-level default import with esModuleInterop)
	//
	const _default: typeof chmpx;
	export default _default;

	//
	// Type named exports
	//
	// [NOTE]
	// ex. "import type { ChmpxNode } from 'chmpx'"
	//
	export type ChmpxNode			= chmpx.ChmpxNode;
	export type ChmpxFactoryType	= chmpx.ChmpxFactoryType;

	// Add convenient alias (PascalCase)
	export type Chmpx				= ChmpxNode;
}

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noexpandtab sw=4 ts=4 fdm=marker
 * vim<600: noexpandtab sw=4 ts=4
 */

package net.psykosoft.psykopaint2.tdsi
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import apparat.memory.Memory;

	public class MemoryManagerTdsi
	{
		static private const memoryBlocks:Vector.<int> = new Vector.<int>();
		static public const memory:ByteArray = new ByteArray();
		static private var reservedMemory:int = 0;
		
		public function MemoryManagerTdsi()
		{}
		
		static public function reserveMemory( amount:int ):int
		{
			memoryBlocks.push( reservedMemory );
			reservedMemory += amount;
			memory.length = Math.max(reservedMemory, ApplicationDomain.MIN_DOMAIN_MEMORY_LENGTH);
			if ( memoryBlocks.length == 1 ){
				memory.endian = Endian.LITTLE_ENDIAN;
				Memory.select(memory);
			}
			return memoryBlocks[memoryBlocks.length-1];
		}
		
		static public function releaseAllMemory():void
		{
			if ( memoryBlocks.length == 0 ) return;
			
			if ( ApplicationDomain.currentDomain.domainMemory == memory )
			{
				ApplicationDomain.currentDomain.domainMemory = null;
			}
			
			memory.clear();
			reservedMemory = 0;
			memoryBlocks.length = 0;
			
		}
		
	}
}
package net.psykosoft.psykopaint2.tdsi
{
	import flash.utils.ByteArray;
	import apparat.asm.__cint;
	import apparat.memory.Memory;
	


	public class MergeUtil
	{
		public function MergeUtil()
		{
		}
		
		public static function mergeRGBAData( _mergeBuffer:ByteArray, len:int ) : void
		{
			var aOffset : int = len + 3;
			
			Memory.select(_mergeBuffer);
			
			for (var i : int = 0; i < len; i = __cint(i + 4), aOffset = __cint(aOffset+4)  ) 
			{
				var rgba:int = Memory.readInt(i);
				var a:int = Memory.readUnsignedByte(aOffset);
				Memory.writeInt( (a << 24) | ((rgba << 8 ) & 0xff0000) | ((rgba >>> 8 ) & 0xff00) | ((rgba >>> 24 ) & 0xff ), i);
			}
			
			Memory.select( MemoryManagerTdsi.memory );
		}

	}
}
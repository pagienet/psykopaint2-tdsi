package net.psykosoft.psykopaint2.tdsi
{
//	import flash.display3D.IndexBuffer3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import apparat.asm.DecLocalInt;
	import apparat.asm.IncLocalInt;
	import apparat.asm.__asm;
	import apparat.asm.__cint;
	import apparat.memory.Memory;

	public class FastBuffer
	{
		protected var _buffer:ByteArray;
		protected var _indexOffset:int;
		private const MAX_VERTEX_COUNT:int = 65535;
		private const MAX_INDEX_COUNT:int = 524286;
		
		public function FastBuffer()
		{
			init();
		}
		
		private function init():void
		{
			_indexOffset = MAX_VERTEX_COUNT*8*4;
			_buffer = new ByteArray();
			_buffer.endian = Endian.LITTLE_ENDIAN;
			_buffer.length = _indexOffset + MAX_INDEX_COUNT * 2;
			
			initIndices();
		}
		
		private function initIndices():void
		{
			activateMemory();
			var j : uint = 0;
			var i : int = 0;
			var offset:int = _indexOffset;
			while ( i < 87381 )
			{
				Memory.writeShort(j,offset);
				__asm(
					IncLocalInt(offset),
					IncLocalInt(offset)
					);
				Memory.writeShort(__cint(j+1),offset);
				__asm(
					IncLocalInt(offset),
					IncLocalInt(offset)
				);
				Memory.writeShort(__cint(j+2),offset);
				__asm(
					IncLocalInt(offset),
					IncLocalInt(offset)
				);
				Memory.writeShort(j,offset);
				__asm(
					IncLocalInt(offset),
					IncLocalInt(offset)
				);
				Memory.writeShort(__cint(j+2),offset);
				__asm(
					IncLocalInt(offset),
					IncLocalInt(offset)
				);
				Memory.writeShort(__cint(j+3),offset);
				__asm(
					IncLocalInt(offset),
					IncLocalInt(offset),
					IncLocalInt(i)
				);
				j = __cint( j + 4 );
				
			}
		}
		
		public function uploadIndicesToBuffer( indexBuffer:IndexBuffer3D, count:int = 524286):void
		{
			indexBuffer.uploadFromByteArray(_buffer,_indexOffset,0, count);
		}
		
		public function uploadVerticesToBuffer( vertexBuffer:VertexBuffer3D, byteArrayOffset:int, startOffset:int, count:int ):void
		{
			vertexBuffer.uploadFromByteArray(_buffer, byteArrayOffset,startOffset, count );
		}
		
		public function addFloatsToVertices( data:Vector.<Number>, offset:int ):void
		{
			activateMemory();
			var i:int =  data.length;
			offset = __cint( offset + data.length * 4 );
			while ( i > 0 )
			{
				__asm(
					DecLocalInt(i)
				);
				offset = __cint( offset - 4 );
				Memory.writeFloat( data[i], offset);
			}
		}
		
		public function addInterleavedFloatsToVertices( data:Vector.<Number>, offset:int, blockCount:int, skipCount:int ):void
		{
			activateMemory();
			var i:int =  0;
			var j:int = 0;
			var l:int = data.length;
			var s:int = skipCount * 4;
			//offset = __cint( offset + (data.length / blockCount) * (blockCount + skipCount) * 4 );
			while ( i < l )
			{
				Memory.writeFloat( data[i], offset);
				offset = __cint( offset + 4 );
				__asm(
					IncLocalInt(i),
					IncLocalInt(j)
				);
				if ( j == blockCount )
				{
					offset = __cint( offset + s );
					j = 0;
				}
			}
		}
		
		public function addInterleavedFloatByteArrayToVertices( data:ByteArray, offset:int, blockCount:int, skipCount:int ):void
		{
			var blockSize:int = blockCount * 4;
			var skipSize:int = skipCount * 4;
			
			var count:int = data.length / blockSize;
			var dataOffset:int = 0;
			_buffer.position = offset;
			for ( var i:int = 0; i < count; i++ )
			{
				_buffer.writeBytes( data,dataOffset,blockSize);
				_buffer.position+=skipSize;
				dataOffset += blockSize;
			}
		}
		
		public function activateMemory():void
		{
			Memory.select(_buffer);
		}
		
	}
}
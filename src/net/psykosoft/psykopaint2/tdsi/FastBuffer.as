package net.psykosoft.psykopaint2.tdsi
{
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.ByteArray;

	import apparat.asm.DecLocalInt;
	import apparat.asm.IncLocalInt;
	import apparat.asm.__asm;
	import apparat.asm.__cint;
	import apparat.memory.Memory;

	public class FastBuffer
	{
		public static const INDEX_MODE_QUADS:int = 0;
		public static const INDEX_MODE_TRIANGLES:int = 1;
		public static const INDEX_MODE_TRIANGLESTRIP:int = 2;
		
		protected var _buffer:ByteArray;
		protected var _baseOffset:int;
		protected var _indexOffset:int;
		protected var _indexMode:int = -1;
		
		private const MAX_VERTEX_COUNT:int = 65535;
		private const MAX_INDEX_COUNT:int = 524286;
		
		public function FastBuffer( indexMode:int = 0)
		{
			init( indexMode );
		}
		
		private function init( indexMode:int = 0):void
		{
			
			_baseOffset = MemoryManagerTdsi.reserveMemory( MAX_VERTEX_COUNT * 16 * 4 + MAX_INDEX_COUNT * 2);
			_indexOffset = _baseOffset + MAX_VERTEX_COUNT*16*4;
			_buffer = MemoryManagerTdsi.memory;
			initIndices(indexMode);
		}
		
		private function initIndices( indexMode:int ):void
		{
			_indexMode = indexMode;
			
			var j : uint = 0;
			var i : int = 0;
			var offset:int = _indexOffset;
			
			if ( _indexMode == INDEX_MODE_QUADS )
			{
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
			} else if ( _indexMode == INDEX_MODE_TRIANGLES )
			{
				while ( i < 87381 )
				{
					Memory.writeShort(j,offset);
					__asm(
						IncLocalInt(offset),
						IncLocalInt(offset),
						IncLocalInt(j),
						IncLocalInt(i)
					);
					Memory.writeShort(j,offset);
					__asm(
						IncLocalInt(offset),
						IncLocalInt(offset),
						IncLocalInt(j),
						IncLocalInt(i)
					);
					Memory.writeShort(j,offset);
					__asm(
						IncLocalInt(offset),
						IncLocalInt(offset),
						IncLocalInt(j),
						IncLocalInt(i)
					);
				}
			} else if ( _indexMode == INDEX_MODE_TRIANGLESTRIP )
			{
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
					Memory.writeShort(__cint(j+1),offset);
					__asm(
						IncLocalInt(offset),
						IncLocalInt(offset)
					);
					Memory.writeShort(__cint(j+3),offset);
					__asm(
						IncLocalInt(offset),
						IncLocalInt(offset)
					);
					Memory.writeShort(__cint(j+2),offset);
					__asm(
						IncLocalInt(offset),
						IncLocalInt(offset),
						IncLocalInt(i)
					);
					j = __cint( j + 2 );
					
				}
			}
		}
		
		public function uploadIndicesToBuffer( indexBuffer:IndexBuffer3D, count:int = 524286):void
		{
			indexBuffer.uploadFromByteArray(_buffer,_indexOffset,0, count);
		}
		
		public function uploadVerticesToBuffer( vertexBuffer:VertexBuffer3D, byteArrayOffset:int, startOffset:int, count:int ):void
		{
			vertexBuffer.uploadFromByteArray(_buffer, _baseOffset + byteArrayOffset,startOffset, count );
		}
		
		public function addFloatsToVertices( data:Vector.<Number>, offset:int ):void
		{
			var i:int =  data.length;
			offset = __cint( _baseOffset +offset + data.length * 4 );
			while ( i > 0 )
			{
				__asm(
					DecLocalInt(i)
				);
				offset = __cint( offset - 4 );
				Memory.writeFloat( data[i], offset);
			}
		}
		
		public function addInterleavedFloatsToVertices( data:Vector.<Number>, offset:int, blockCount:int, skipCount:int, dataBlocksToWrite:int = -1 ):void
		{
			var i:int =  0;
			var j:int = 0;
			var l:int = dataBlocksToWrite == -1 ? data.length : dataBlocksToWrite;
			var s:int = skipCount * 4;
			//offset = __cint( offset + (data.length / blockCount) * (blockCount + skipCount) * 4 );
			offset += _baseOffset;
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
			_buffer.position = _baseOffset + offset;
			for ( var i:int = 0; i < count; i++ )
			{
				_buffer.writeBytes( data,dataOffset,blockSize);
				_buffer.position+=skipSize;
				dataOffset += blockSize;
			}
		}
		
		public function get indexMode():int
		{
			return _indexMode;
		}
		
		public function set indexMode( value:int ):void
		{
			if ( value != _indexMode )
			{
				initIndices( value );
			}
		}
		
	}
}
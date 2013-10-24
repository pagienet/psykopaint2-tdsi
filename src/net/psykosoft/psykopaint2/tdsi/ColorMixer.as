package net.psykosoft.psykopaint2.tdsi
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	import apparat.asm.AbcMultinameL;
	import apparat.asm.AbcNamespace;
	import apparat.asm.AbcNamespaceSet;
	import apparat.asm.Add;
	import apparat.asm.AddInt;
	import apparat.asm.ConvertInt;
	import apparat.asm.DecLocalInt;
	import apparat.asm.GetLocal;
	import apparat.asm.GetProperty;
	import apparat.asm.IfGreaterThan;
	import apparat.asm.IncLocalInt;
	import apparat.asm.NamespaceKind;
	import apparat.asm.PushByte;
	import apparat.asm.SetInt;
	import apparat.asm.ShiftLeft;
	import apparat.asm.__asm;
	import apparat.asm.__cint;
	import apparat.memory.Memory;

	public class ColorMixer
	{
		private var _baseOffset:int = -1;
		private var _targetOffset:int = -1;
		
		private var _blockSize:int;
		
		private var _data:ByteArray;
		private var _displayMap:BitmapData;
		
		
		public function ColorMixer( displayMap:BitmapData )
		{
			init( displayMap );
		}
		
		private function init( displayMap:BitmapData ):void
		{
			_displayMap = displayMap;
			_blockSize = displayMap.width * displayMap.height;
			if ( _baseOffset == -1 )
			{
				_baseOffset = MemoryManagerTdsi.reserveMemory(_blockSize * 8 );
				_data = MemoryManagerTdsi.memory;
			}
			_targetOffset = _baseOffset + _blockSize * 4;
			
			
			var i:int = _blockSize;
			var bo:int = _baseOffset;
			var vc:Vector.<uint> = displayMap.getVector( displayMap.rect );
			__asm(
				'loop:',
				DecLocalInt(i),
				GetLocal(vc),
				GetLocal(i),
				GetProperty(AbcMultinameL(AbcNamespaceSet(AbcNamespace(NamespaceKind.PACKAGE, "")))),
				ConvertInt,
				GetLocal(i),
				PushByte(2),
				ShiftLeft,
				GetLocal(bo),
				Add,
				SetInt,
				GetLocal(i),
				PushByte(0),
				IfGreaterThan('loop')
			);
			
			
			
		}
			
		
		public function update( centerX:Number, centerY:Number, speedX:Number, speedY:Number, radius:Number, brushColor:uint, colorInfluence:Number ):void
		{
			var w:int = _displayMap.width;
			var h:int = _displayMap.height;
			var rsq:Number = radius * radius;
			var rx:int;
			var ry:int;
			var targetIndex:int = _targetOffset;
			var sourceIndex:int;
			var baseIndex:int = _baseOffset;
			for ( var y:int = 0; y < h; y++ )
			{
				var dy:Number = y - centerY;
				for ( var x:int = 0; x < w; x++ )
				{
					var dx:Number = x - centerX;
					var d:Number = dx*dx+dy*dy;
					rx = x;
					ry = y;
					
					if ( d < rsq )
					{
						d = 1 - Math.sqrt(d) / radius;
						d*=d;
						rx -= speedX * d;
						ry -= speedY * d;
						if ( rx < 0 ) rx = 0;
						if ( ry < 0 ) ry = 0;
						if ( rx >= w ) rx = w-1;
						if ( ry >= h ) ry = h-1;
					}
					
					if ( rx != 0 || ry != 0 )
					{
						sourceIndex = baseIndex + ((y * w + x) << 2);
						var argb1:uint = Memory.readInt(sourceIndex);
						var a1:int = (argb1 >>> 24) & 0xff;
						var r1:int = (argb1 >>> 16) & 0xff;
						var g1:int = (argb1 >>> 8) & 0xff;
						var b1:int = argb1 & 0xff;
						
						sourceIndex = baseIndex + ((ry * w + rx) << 2);
						var argb2:uint = Memory.readInt(sourceIndex);
						var a2:int = (argb2 >>> 24) & 0xff;
						var r2:int = (argb2 >>> 16) & 0xff;
						var g2:int = (argb2 >>> 8) & 0xff;
						var b2:int = argb2 & 0xff;
						
						var a:int = a1 * d + a2 * (1-d);
						var r:int = r1 * d + r2 * (1-d);
						var g:int = g1 * d + g2 * (1-d);
						var b:int = b1 * d + b2 * (1-d);
						
						Memory.writeInt(a<<24 | r << 16 | g << 8 | b ,targetIndex );
					} else {
						sourceIndex = baseIndex + ((ry * w + rx) << 2);
						Memory.writeInt(Memory.readInt(sourceIndex),targetIndex );
					}
					targetIndex = __cint( targetIndex + 4 );
				}
			}
			
			
			_data.position = _targetOffset;
			_displayMap.setPixels( _displayMap.rect, _data );
			
			var tmp:int = _targetOffset;
			_targetOffset = _baseOffset;
			_baseOffset = tmp;
		}
	}
}
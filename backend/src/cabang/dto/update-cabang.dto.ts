import { PartialType } from '@nestjs/mapped-types';
import { CreateCabangDto } from './create-cabang.dto';

export class UpdateCabangDto extends PartialType(CreateCabangDto) {}

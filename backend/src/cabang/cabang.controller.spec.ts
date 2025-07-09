import { Test, TestingModule } from '@nestjs/testing';
import { CabangController } from './cabang.controller';

describe('CabangController', () => {
  let controller: CabangController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CabangController],
    }).compile();

    controller = module.get<CabangController>(CabangController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

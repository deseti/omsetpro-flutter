import { Test, TestingModule } from '@nestjs/testing';
import { TimController } from './tim.controller';

describe('TimController', () => {
  let controller: TimController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [TimController],
    }).compile();

    controller = module.get<TimController>(TimController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AppComponent } from './app.component';
import { By } from '@angular/platform-browser';

describe('AppComponent', () => {
  let component: AppComponent;
  let fixture: ComponentFixture<AppComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ AppComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(AppComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should call the onClick method when the button is clicked', () => {
    spyOn(component, 'onButtonClick');

    let button = fixture.debugElement.query(By.css('button'));
    button.triggerEventHandler('click', null);

    expect(component.onButtonClick).toHaveBeenCalled();
  });
});